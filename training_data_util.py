"""Classes & functions supporting compile_training_data.py."""

from bs4 import BeautifulSoup as Soup
from bs4.element import Comment
from csv import reader
from io import BytesIO
from os import mkdir
from os.path import abspath, exists, join
from PyPDF2.pdf import PdfFileReader
from requests import get
from string import ascii_letters, ascii_uppercase, printable

class Element(object):
	"""Models a single cell within a table of training data."""
	LABEL = 'LABEL'
	URL = 'URL'
	TEXT = 'TEXT'
	KEYWORDS = 'KEYWORDS'
	ALL_TYPES = {LABEL, URL, TEXT, KEYWORDS}

	KEYWORD_CHARS = set(ascii_letters + '-, ')
	LABEL_CHARS = set(ascii_uppercase + '_')

	def __init__(self, string):
		self.content = self.clean(string)
		self.type = self.categorize(string)

	@staticmethod
	def clean(string):
		"""Remove unprintable characters and excess whitespace."""
		string = string.strip()
		cleaned_string = ''.join([_ for _ in string if _ in printable])
		while cleaned_string.endswith(','):
			cleaned_string = cleaned_string.strip(',')
		return cleaned_string

	@staticmethod
	def categorize(string):
		"""Recognize the element type based on content."""
		if len(string) == 0:
			return Element.TEXT
		if (' ' not in string) and string.startswith('http'):
			return Element.URL
		if set(string).issubset(Element.LABEL_CHARS):
			return Element.LABEL
		if (set(string).issubset(Element.KEYWORD_CHARS) and
			(string.count(',') > string.count(' ') / 3.0)
		):
			return Element.KEYWORDS
		return Element.TEXT


class CleanedRow(object):
	def __init__(self, elements):
		self.elements = elements
		count = self.count(Element.URL)
		if count > 1:
			raise ValueError(
				'Cannot have more than one URL per row. Found {}.'.format(count)
			)
		count = self.count(Element.LABEL)
		if count > 1:
			raise ValueError(
				'Cannot have more than one label per row. Found {}'.format(
					count
				)
			)
		count = self.count(Element.KEYWORDS)
		if count > 1:
			raise ValueError(
				'Cannot have more than one block of keywords per row. Found {}'.format(
					count
				))
		self._internal_label = self.get_label_from_elements()
		self.label = None

	def count(self, element_type):
		"""Return the number of elements matching the given type."""
		if element_type not in Element.ALL_TYPES:
			raise ValueError('Invalid Element type {}'.format(element_type))
		return len([ele for ele in self.elements if ele.type == element_type])

	def _get_element_content_matching_type(self, element_type):
		"""Returns the first element matching the given type.

		Returns None if no such element is found.
		"""
		for ele in self.elements:
			if ele.type == element_type:
				return ele.content

	def get_label_from_elements(self):
		"""Looks up the Label for the row, ignoring context from other rows."""
		return self._get_element_content_matching_type(Element.LABEL)

	def get_url_from_elements(self):
		"""Looks up the URL on the row."""
		return self._get_element_content_matching_type(Element.URL)

	def get_keywords_from_elements(self):
		"""Looks up the block of keywords on the row."""
		return self._get_element_content_matching_type(Element.KEYWORDS)

	def set_label(self, default_label):
		"""Sets an explicit label, including context from previous rows."""
		internal_label = self.get_label_from_elements()
		if internal_label is None:
			self.label = default_label
		else:
			self.label = self._internal_label
		return self.label


class TableReader(object):
	"""Reads a table of training data copied from Confluence to CSV."""
	def __init__(self, filename):
		self.filename = filename
		self.current_label = None
		self.urls = {}
		self.keywords = {}

	def read(self):
		print('Reading from {}'.format(self.filename))
		with open(self.filename, 'r') as f:
			r = reader(f.readlines())
			for row in r:
				elements = [Element(string) for string in row]
				cleaned = CleanedRow(elements)
				self.process_row(cleaned)
		print('Done with {}'.format(self.filename))

	def process_row(self, cleaned_row):
		"""Copy a single input row into lists of urls and keywords"""
		self.current_label = cleaned_row.set_label(
			default_label=self.current_label
		)
		if self.current_label is None:
			return
		current_url = cleaned_row.get_url_from_elements()
		if current_url is not None:
			if self.current_label in self.urls:
				self.urls[self.current_label].add(current_url)
			else:
				self.urls[self.current_label] = {current_url}
		current_keywords = cleaned_row.get_keywords_from_elements()
		if current_keywords is not None:
			current_keywords = current_keywords.split(',')
			current_keywords = {word.strip() for word in current_keywords}
			if self.current_label in self.keywords:
				self.keywords[self.current_label] |= current_keywords
			else:
				self.keywords[self.current_label] = current_keywords


class PageScraper(object):
	TIMEOUT = 60
	HIDDEN_ELEMENTS = {'style', 'script', 'head', 'title', 'meta', 'document'}

	def scrape(self, url):
		"""Download the given URL and return the text."""
		response = self.download_page(url)
		return self.convert_to_text(response)

	# Internal utility methods

	def download_page(self, url):
		"""Connect to and download the targeted URL.  Returns the raw HTML."""
		response = get(url, timeout=self.TIMEOUT)
		if 300 <= response.status_code < 400:
			raise IOError('Target URL has moved: {}'.format(response.reason))
		elif 400 <= response.status_code < 500:
			raise IOError(
				'Target URL cannot be read as specified: {}'.format(
					response.reason
				)
			)
		elif response.status_code >= 500:
			raise IOError(
				'Target URL had an internal error: {}'.format(response.reason))
		return response

	def spot_visible(self, element):
		"""Return True iff the given element would be visibile to a user."""
		if element.parent.name in self.HIDDEN_ELEMENTS:
			return False
		if isinstance(element, Comment):
			return False
		return True

	def convert_to_text(self, response):
		"""Convert whatever format was read to plain text.

		Chooses the converter based solely on the content-type in the headers.
		"""

		# Requests headers use requests.structures.CaseInsensitiveDict, so we
		# don't need to worry about the case of the header key.  We convert the
		# content-type value to lower case to make checks simpler.
		content_type = response.headers.get(
			'content-type',
			'text/html; charset=UTF-8'
		).lower()

		if 'pdf' in content_type:
			return self.pdf_to_text(response.content)
		elif 'html' in content_type:
			return self.html_to_text(response.text)
		elif 'text' not in content_type:
			# Assume HTML because it's common
			print(
				'WARNING: Treating unrecognized content type {} as HTML.'.format(
					content_type
				)
			)
			return self.html_to_text(response.text)

		return response.text

	def html_to_text(self, html):
		"""Strips HTML tags and other markup from the file, leaving text."""
		soup = Soup(html, "html.parser")
		text = soup.find_all(text=True)
		visible_texts = filter(self.spot_visible, text)
		return ''.join(visible_texts)

	@staticmethod
	def pdf_to_text(content):
		"""Convert downloaded PDF into an approximate plain-text version."""
		reader = PdfFileReader(BytesIO(content))
		num_pages = reader.getNumPages()
		return ''.join([
			reader.getPage(pageNum).extractText()
			for pageNum in range(num_pages)
		])


class DataWriter(object):
	"""Reads the specified website and writes"""
	KEYWORD_FILE_NAME = 'all_keywords.csv'

	def __init__(self, target_directory, table_reader, force_write=False):
		self.dir = abspath(target_directory)
		self.urls = table_reader.urls.copy()
		self.keywords = table_reader.keywords.copy()
		self.force_write = force_write
		self.failed_urls = set()
		self.scraper = PageScraper()

	def write(self):
		"""Run the Data Writer."""
		self.create_dir_if_needed()
		self.write_keyword_file()
		self.write_scraped_pages()
		print('Write complete.')
		print('{} Failed URLs:'.format(len(self.failed_urls)))
		print('\n'.join(self.failed_urls))

	def create_dir_if_needed(self):
		"""Make sure there's a directory in which to store the training data."""
		if not exists(self.dir):
			mkdir(self.dir)

	def okay_to_write(self, filename):
		"""Tests if a file exists, and if it does, if it can be overwritten."""
		if exists(filename):
			if self.force_write:
				print('WARNING: Overwriting file {}.'.format(filename))
			else:
				print('ERROR: Cannot overwrite file {}.'.format(filename))
				raise FileExistsError('File {} already exists.'.format(
					filename
				))
		else:
			print('Writing to {}'.format(filename))

	def write_keyword_file(self):
		"""Write the output keyword file."""
		keyword_file = abspath(join(self.dir, self.KEYWORD_FILE_NAME))
		self.okay_to_write(keyword_file)
		with open(keyword_file, 'w') as kf:
			for label, words in self.keywords.items():
				kf.write('{}, {}\n'.format(label, ', '.join(words)))

	def write_scraped_pages(self):
		"""Write the scraped pages for all URLs."""
		category_index = 1
		category_count = len(self.urls)
		for key, urls in self.urls.items():
			print('Beginning category {}/{}.'.format(
				category_index,
				category_count
			))
			self.write_pages_for_category(key, urls)

	def write_page_for_url(self, output_file, url):
		"""Download the targeted page and save it to a file."""
		self.okay_to_write(output_file)
		text = self.scraper.scrape(url)
		self.save_page_text(output_file, text)

	@staticmethod
	def save_page_text(output_file, text):
		"""Saves the given text to a file."""
		with open(output_file, 'w') as pf:
			pf.write(text)

	def write_pages_for_category(self, category, urls):
		"""Write one file per URL."""
		next_index = 1
		for url in urls:
			output_file = abspath(
				join(self.dir, '{}_{}.txt'.format(category, next_index))
			)
			try:
				self.write_page_for_url(output_file, url)
			except Exception as err:
				# This is very broad, but if _anything_ goes wrong in the
				# processing of the page, it should be caught and logged.
				# PdfReadError and RequestError are both plausible, but have no
				# common superclass more specific than Exception.
				print('WARNING: Target URL {} could not be read: {}'.format(
					url,
					err
				))
				self.failed_urls.add(url)
			next_index += 1
