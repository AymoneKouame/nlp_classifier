"""Tests for code supporting the compile_training_data utility.

Can be run from the root directory of this repository with this command line:
	python3 -m unittest tests.test_training_data_compilation
"""

from mock import mock_open, patch
from requests import Response
from os.path import abspath
from unittest import TestCase

from utility.training_data_util import (
	CleanedRow,
	DataWriter,
	Element,
	PageScraper,
	TableReader
)


# helper functions
def generate_fake_request_with_code(status_code):
	response = Response()
	response.status_code = status_code
	response._content = b'This is sample text'
	return response


def strings_to_row(*strings):
	return CleanedRow([Element(s) for s in strings])


# Test classes
class CleanedRowTests(TestCase):

	def test_init_multi_urls(self):
		ele = [Element(s) for s in (
			'https://www.guildwars2.com/en/',
			'https://en.wikipedia.org/wiki/NATO_phonetic_alphabet'
		)]
		with self.assertRaises(ValueError):
			CleanedRow(ele)

	def test_init_multi_labels(self):
		ele = [Element(s) for s in (
			'BIG_IMPORTANT_ROW',
			'UNIMPORTANT_CATEGORY'
		)]
		with self.assertRaises(ValueError):
			CleanedRow(ele)

	def test_init_multi_keywords(self):
		ele = [Element(s) for s in (
			'ich, ni, san, shi, go, roku, shichi, hachi, kyu, jyu, jyu-ich',
			'uno, dos, tres, quattro, cinco, seis, siete, ocho, nueve, diez'
		)]
		with self.assertRaises(ValueError):
			CleanedRow(ele)

	def test_count(self):
		row = strings_to_row(
			'alpha',
			'bravo',
			'charlie',
			'https://en.wikipedia.org/wiki/NATO_phonetic_alphabet'
		)
		self.assertEqual(row.count(Element.LABEL), 0)
		self.assertEqual(row.count(Element.URL), 1)
		self.assertEqual(row.count(Element.TEXT), 3)
		self.assertEqual(row.count(Element.KEYWORDS), 0)

	def test_get_element_content_matching_type(self):
		row = strings_to_row(
			'THIS_IS_A_LABEL',
			'Here is some text, you know?',
			'k, e, y, w, o, r, d, is, wha, t hi, s is , suppos, ed to b, e',
			'https://not.a.real.site?i.hope'
		)
		self.assertEqual(
			row._get_element_content_matching_type(Element.LABEL),
			'THIS_IS_A_LABEL'
		)
		self.assertEqual(
			row._get_element_content_matching_type(Element.URL),
			'https://not.a.real.site?i.hope'
		)
		self.assertEqual(
			row._get_element_content_matching_type(Element.TEXT),
			'Here is some text, you know?'
		)
		self.assertEqual(
			row._get_element_content_matching_type(Element.KEYWORDS),
			'k, e, y, w, o, r, d, is, wha, t hi, s is , suppos, ed to b, e'
		)

	def test_get_label_from_elements(self):
		row = strings_to_row(
			'THIS_IS_A_LABEL',
			'Here is some text, you know?',
			'k,ey, word, is, wha, t hi, s is , SUPPOS, ed to b, e',
			'https://not.a.real.site?i.hope'
		)
		self.assertEqual(
			row.get_label_from_elements(),
			'THIS_IS_A_LABEL',
		)

	def test_get_url_from_elements(self):
		row = strings_to_row(
			'THIS_IS_NOT_A_LABEL',
			'Is this text?',
			'ke, y w, or, D, is, wha, t hi, s is , suppos, ed to b, e',
			'https://somewhere.over.the.rainbow'
		)
		self.assertEqual(
			row.get_url_from_elements(),
			'https://somewhere.over.the.rainbow'
		)

	def test_get_keywords_from_elements(self):
		row = strings_to_row(
			'THIS_IS_A_LABEL',
			'Here is some text, you know?',
			'k, e, y, w, o, r, d, is, wha, t hi, s is , suppos, ed to b, e',
			'https://not.a.real.site?i.hope'
		)
		self.assertEqual(
			row.get_keywords_from_elements(),
			'k, e, y, w, o, r, d, is, wha, t hi, s is , suppos, ed to b, e'
		)

	def test_set_label_row_null(self):
		row = strings_to_row(
			'alpha TEXt is grand',
			'Some labels wander by mistake!',
			'charlie, delta, EPSILON',
			'https://en.wikipedia.org/wiki/NATO_phonetic_alphabet'
		)
		row.set_label('LABEL')
		self.assertEqual(row.label, 'LABEL')

	def test_set_label_both_set(self):
		row = strings_to_row(
			'alpha TEXt is grand',
			'SOME_LABEL',
			'charlie, delta, EPSILON',
			'https://en.wikipedia.org/wiki/NATO_phonetic_alphabet'
		)
		row.set_label('CHORUS')
		self.assertEqual(row.label, 'SOME_LABEL')

	def test_set_label_previous_null(self):
		row = strings_to_row(
			'alpha TEXt is grand',
			'SOME_LABEL',
			'charlie, delta, EPSILON',
			'https://en.wikipedia.org/wiki/NATO_phonetic_alphabet'
		)
		row.set_label(None)
		self.assertEqual(row.label, 'SOME_LABEL')

	def test_set_label_both_null(self):
		row = strings_to_row(
			'alpha TEXt is grand',
			'Sisters of Mercy',
			'charlie, delta, EPSILON',
			'https://en.wikipedia.org/wiki/NATO_phonetic_alphabet'
		)
		row.set_label(None)
		self.assertEqual(row.label, None)


class PageScraperTests(TestCase):
	def setUp(self):
		self.scraper = PageScraper()

	@patch('utility.training_data_util.get')
	def test_scrape(self, requests_get):
		requests_get.return_value = generate_fake_request_with_code(200)
		text = self.scraper.scrape('https://any.site/at/all')
		self.assertEqual(text, 'This is sample text')

	@patch('utility.training_data_util.get')
	def test_download_page_success(self, requests_get):
		requests_get.return_value = generate_fake_request_with_code(200)
		response = self.scraper.download_page(
			'http://not.a.real.site/page/content/fake.html'
		)
		requests_get.assert_called_once_with(
			'http://not.a.real.site/page/content/fake.html',
			timeout=self.scraper.TIMEOUT
		)
		self.assertIsInstance(response, Response)
		self.assertEqual(response.text, 'This is sample text')

	@patch('utility.training_data_util.get')
	def test_download_page_redirect(self, requests_get):
		requests_get.return_value = generate_fake_request_with_code(300)
		with self.assertRaises(IOError):
			self.scraper.download_page(
				'http://not.a.real.site/page/content/fake.html'
			)
		requests_get.assert_called_once_with(
			'http://not.a.real.site/page/content/fake.html',
			timeout=self.scraper.TIMEOUT
		)

	@patch('utility.training_data_util.get')
	def test_download_page_request_err(self, requests_get):
		requests_get.return_value = generate_fake_request_with_code(400)
		with self.assertRaises(IOError):
			self.scraper.download_page(
				'http://not.a.real.site/page/content/fake.html'
			)
		requests_get.assert_called_once_with(
			'http://not.a.real.site/page/content/fake.html',
			timeout=self.scraper.TIMEOUT
		)

	@patch('utility.training_data_util.get')
	def test_download_page_server_err(self, requests_get):
		requests_get.return_value = generate_fake_request_with_code(500)
		with self.assertRaises(IOError):
			self.scraper.download_page(
				'http://not.a.real.site/page/content/fake.html'
			)
		requests_get.assert_called_once_with(
			'http://not.a.real.site/page/content/fake.html',
			timeout=self.scraper.TIMEOUT
		)


class DataWriterTests(TestCase):
	def get_mocked_table_reader(self):
		tr = TableReader('fake.csv')
		tr.keywords = {
			'A': 'alpha, apple, ancient, advocate, avocado, arrest, army, act',
			'B': 'beta, bravo, best, bank, bankrupt, balance, business, bolo',
		}
		tr.urls = {
			'A': {
				'http://somewhere.com',
				'http://not.a.real.address'
			},
			'B': {
				'actual contents shouldn''t matter',
				'for this test'
			}
		}
		return tr

	def test_init_default(self):
		tr = TableReader('smarmy.csv')
		dw = DataWriter('/usr/place/', tr)
		self.assertEqual(dw.dir, '/usr/place')
		self.assertEqual(dw.urls, tr.urls)
		self.assertEqual(dw.keywords, tr.keywords)
		self.assertFalse(dw.force_write)
		self.assertEqual(len(dw.failed_urls), 0)

	def test_init_force(self):
		tr = TableReader('thing.csv')
		dw = DataWriter('/root/place/', tr, force_write=True)
		self.assertEqual(dw.dir, '/root/place')
		self.assertEqual(dw.urls, tr.urls)
		self.assertEqual(dw.keywords, tr.keywords)
		self.assertTrue(dw.force_write)
		self.assertEqual(len(dw.failed_urls), 0)

	def test_init_no_force(self):
		tr = TableReader('all about the stuff.csv')
		dw = DataWriter('c:\windows', tr, force_write=False)
		self.assertEqual(dw.dir, abspath('c:\windows'))
		self.assertEqual(dw.urls, tr.urls)
		self.assertEqual(dw.keywords, tr.keywords)
		self.assertFalse(dw.force_write)
		self.assertEqual(len(dw.failed_urls), 0)

	@patch('utility.training_data_util.get')
	@patch('utility.training_data_util.exists')
	@patch('utility.training_data_util.mkdir')
	def test_write(self, os_mkdir, os_path_exists, requests_get):
		requests_get.return_value = generate_fake_request_with_code(200)
		os_path_exists.return_value = False
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr)
		with patch('utility.training_data_util.open', mock_open()) as mo:
			dw.write()
		mo.assert_called()
		os_mkdir.assert_called_once_with(dw.dir)

	@patch('utility.training_data_util.exists')
	@patch('utility.training_data_util.mkdir')
	def test_create_dir_if_needed_exists(self, os_mkdir, os_path_exists):
		os_path_exists.return_value = True
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr)
		dw.create_dir_if_needed()
		os_path_exists.assert_called_once_with(dw.dir)
		os_mkdir.assert_not_called()

	@patch('utility.training_data_util.exists')
	@patch('utility.training_data_util.mkdir')
	def test_create_dir_if_needed_does_not_exist(self, os_mkdir, os_path_exists):
		os_path_exists.return_value = False
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr)
		dw.create_dir_if_needed()
		os_path_exists.assert_called_once_with(dw.dir)
		os_mkdir.assert_called_once_with(dw.dir)

	@patch('utility.training_data_util.exists')
	def test_okay_to_write_does_not_exist(self, os_path_exists):
		os_path_exists.return_value = False
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr, force_write=False)
		dw.okay_to_write('test_file.html')
		os_path_exists.assert_called_once_with('test_file.html')

	@patch('utility.training_data_util.exists')
	def test_okay_to_write_force_overwrite(self, os_path_exists):
		os_path_exists.return_value = True
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr, force_write=True)
		dw.okay_to_write('test_file.html')
		os_path_exists.assert_called_once_with('test_file.html')

	@patch('utility.training_data_util.exists')
	def test_okay_to_write_existence_blocks(self, os_path_exists):
		os_path_exists.return_value = True
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr, force_write=False)
		with self.assertRaises(FileExistsError):
			dw.okay_to_write('test_file.html')
		os_path_exists.assert_called_once_with('test_file.html')

	def test_write_keyword_file(self):
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr)
		with patch('utility.training_data_util.open', mock_open()) as mo:
			dw.write_keyword_file()
		mo.assert_called_once()

	@patch('utility.training_data_util.get')
	def test_write_scraped_pages(self, mock_get):
		mock_get.return_value = generate_fake_request_with_code(200)
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr)
		with patch('utility.training_data_util.open', mock_open()) as mo:
			dw.write_scraped_pages()
		mo.assert_called()

	@patch('utility.training_data_util.get')
	def test_write_page_for_url(self, mock_get):
		mock_get.return_value = generate_fake_request_with_code(200)
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr)
		with patch('utility.training_data_util.open', mock_open()) as mo:
			dw.write_page_for_url('test.file', 'http://test.site')
		mock_get.assert_called_once_with(
			'http://test.site',
			timeout=PageScraper.TIMEOUT
		)
		mo.assert_called()

	@patch('utility.training_data_util.get')
	def test_write_pages_for_category(self, mock_get):
		mock_get.return_value = generate_fake_request_with_code(200)
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr)
		with patch('utility.training_data_util.open', mock_open()) as mo:
			dw.write_pages_for_category('LABEL_FOUR', ['http://test.com'])
		mock_get.assert_called_once_with(
			'http://test.com',
			timeout=PageScraper.TIMEOUT
		)
		mo.assert_called()

	def test_save_page_text(self):
		tr = self.get_mocked_table_reader()
		dw = DataWriter('somewhere', tr)
		with patch('utility.training_data_util.open', mock_open()) as mopen:
			dw.save_page_text('test.file.html', 'this is some text to save')
		mopen.assert_called_once_with('test.file.html', 'w')


class ElementTests(TestCase):
	def test_init(self):
		url = 'http://www.google.com'
		ele = Element(url)
		self.assertEqual(ele.content, url)
		self.assertEqual(ele.type, Element.URL)

	def test_clean(self):
		self.assertEqual(
			Element.clean(' {}!!hello, world\u8433  what, me worry? '),
			'{}!!hello, world  what, me worry?'
		)

	def test_categorize_keywords(self):
		self.assertEqual(
			Element.categorize('a, beta, gamma, charlie, bravo, ich, dos'),
			Element.KEYWORDS
		)

	def test_categorize_label(self):
		self.assertEqual(Element.categorize('FEATURE_RATE'), Element.LABEL)

	def test_categorize_text(self):
		self.assertEqual(
			Element.categorize('The brown cow, now?'),
			Element.TEXT
		)

	def test_categorize_url(self):
		self.assertEqual(
			Element.categorize('https://washingtonpost.com'),
			Element.URL
		)

	def test_categorize_empty(self):
		self.assertEqual(Element.categorize(''), Element.TEXT)


class TableReaderTests(TestCase):
	def test_init(self):
		tr = TableReader('file.txt')
		self.assertEqual(tr.filename, 'file.txt')
		self.assertIsNone(tr.current_label)
		self.assertEqual(len(tr.urls), 0)
		self.assertEqual(len(tr.keywords), 0)

	def test_process_row_with_data_initially_bare(self):
		tr = TableReader('fake_training_data.csv')
		cr = strings_to_row(
			'LABEL_ONE',
			'keywords, key, word, lock, what',
			'this is still text-like',
			'http://url.org'
		)
		tr.process_row(cr)
		self.assertEqual(tr.urls, {'LABEL_ONE': {'http://url.org'}})
		self.assertEqual(
			tr.keywords,
			{'LABEL_ONE': {'keywords', 'key', 'word', 'lock', 'what'}}
		)
		self.assertEqual(tr.current_label, 'LABEL_ONE')

	def test_process_row_no_data_initially_bare(self):
		tr = TableReader('fake_training_data.csv')
		cr = strings_to_row(
			'Label',
			'Text',
			'Keywords',
			'Urls'
		)
		tr.process_row(cr)
		self.assertEqual(tr.urls, {})
		self.assertEqual(tr.keywords, {})
		self.assertEqual(tr.current_label, None)

	def test_process_row_with_data_previous_record_same_label(self):
		tr = TableReader('fake_training_data.csv')
		tr.urls = {'LABEL_ONE': {'http://some-url.org'}}
		tr.keywords = {'LABEL_ONE': {'Hello', 'world', 'goodbye', 'void'}}
		tr.current_label = 'LABEL_ONE'
		cr = strings_to_row(
			'LABEL_ONE',
			'keywords, key, word, lock, what',
			'This is still text-like',
			'https://url.org'
		)
		tr.process_row(cr)
		self.assertEqual(
			tr.urls,
			{'LABEL_ONE': {
				'https://url.org',
				'http://some-url.org'
			}}
		)
		self.assertEqual(
			tr.keywords,
			{'LABEL_ONE': {'keywords', 'key', 'word', 'lock', 'what', 'Hello', 'world', 'goodbye', 'void'}}
		)
		self.assertEqual(tr.current_label, 'LABEL_ONE')

	def test_process_row_with_data_previous_record_different_label(self):
		tr = TableReader('fake_training_data.csv')
		tr.urls = {'LABEL_ONE': {'http://some-url.org'}}
		tr.keywords = {'LABEL_ONE': {'Hello', 'world', 'goodbye', 'void'}}
		tr.current_label = 'LABEL_ONE'
		cr = strings_to_row(
			'LABEL_TWO',
			'keywords, key, word, lock, what',
			'This is still text-like',
			'https://url.org'
		)
		tr.process_row(cr)
		self.assertEqual(
			tr.urls,
			{
				'LABEL_ONE': {'http://some-url.org'},
				'LABEL_TWO': {'https://url.org'},
			}
		)
		self.assertEqual(
			tr.keywords,
			{
				'LABEL_ONE': {'Hello', 'world', 'goodbye', 'void'},
				'LABEL_TWO': {'keywords', 'key', 'word', 'lock', 'what'}
			}
		)
		self.assertEqual(tr.current_label, 'LABEL_TWO')

	def test_process_row_with_no_label(self):
		tr = TableReader('fake_training_data.csv')
		tr.urls = {'LABEL_ONE': {'http://some-url.org'}}
		tr.keywords = {'LABEL_ONE': {'Hello', 'world', 'goodbye', 'void'}}
		tr.current_label = 'LABEL_ONE'
		cr = strings_to_row(
			'',
			'keywords, key, word, lock, what',
			'This is still text-like',
			'https://url.org'
		)
		tr.process_row(cr)
		self.assertEqual(
			tr.urls,
			{'LABEL_ONE': {
				'https://url.org',
				'http://some-url.org'
			}}
		)
		self.assertEqual(
			tr.keywords,
			{'LABEL_ONE': {'keywords', 'key', 'word', 'lock', 'what', 'Hello', 'world', 'goodbye', 'void'}}
		)
		self.assertEqual(tr.current_label, 'LABEL_ONE')

	def test_process_row_with_no_data(self):
		tr = TableReader('fake_training_data.csv')
		tr.urls = {'LABEL_ONE': {'http://some-url.org'}}
		tr.keywords = {'LABEL_ONE': {'Hello', 'world', 'goodbye', 'void'}}
		tr.current_label = 'LABEL_ONE'
		cr = strings_to_row(
			'',
			'',
			'Look! Text! Admire it!',
			''
		)
		tr.process_row(cr)
		self.assertEqual(
			tr.urls,
			{'LABEL_ONE': {'http://some-url.org'}}
		)
		self.assertEqual(
			tr.keywords,
			{'LABEL_ONE': {'Hello', 'world', 'goodbye', 'void'}}
		)
		self.assertEqual(tr.current_label, 'LABEL_ONE')
