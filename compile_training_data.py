#!/usr/bin/env python3
"""Convert Confluence-based table of training data to R-friendly format.
[confluence training data pages](https://whitehawkcec.atlassian.net/wiki/spaces/WDP/pages/14920029/Data+Structures+supporting+natural-language+processing+feature+definition)
Training data table must have the following format:
CATEGORY | key, words | https://www.domain.com

# Summary
1. Highlight training data table on Confluence, and press <Copy>, usually Command-C on Mac.
2. Open Excel and a new Workbook
3. Put the cursor at the top-left cell, and press <Paste>, usually Command-V on Mac.
4. Save as CSV.
5. Run this script: $ python ./utility/compile_training_data.py <input/path/file>.csv <output/path/dir>

By default, this script will not overwrite existing files.

# Example
For example, assume there's a Confluence page with a table of training data for
recognizing articles discussing different languages based on the words used. The
page might be called "Languages" and have a table of three columns: "Language
Name", "Keywords", and "URLs".  The "Language Name" column will preferably label
each language in all-caps text, separating words by underscores. The "Keywords"
column will preferably have multiple words or short phrases indicative of each
language, with the words & phrases separated by commas. The "URLs" column would
contain URLs of pages with sample websites using the corresponding languages.
Each URL would be on a separate line, and each would begin with "http://" or
"https://" as appropriate.

The user would cut and paste this entire table into a blank Excel workbook, and
export the result to a CSV, "language_training.csv". The resulting workbook and
CSV would have multiple blank cells, since each of the original blocks of URLs
would now be split across multiple lines, with only the first having
corresponding entries in the Language Name and Keywords columns. Once this CSV
exists, the user could go to the base directory for the repository and run
	./utility/compile_training_data.py language_training.csv languages

This would then create a subdirectory named "languages", and put in it one file
of keywords ("all_keywords.csv") and one file for each successfully-read URL.
The URL files would have names based the language labels, e.g. ENGLISH_1.html,
ENGLISH_2.html, FRENCH_1.html, SPANISH_1.html, ...  Each of the *.html files is
the raw contents of the successfully-read page, exclusive of any images, css or
other supplemental files. The file "all_keywords.csv" contains one row per
language, with the first entry in each row being the label for the language.

Run the command with the flag or "-h" or "--help" for more details.
"""

from argparse import ArgumentParser
from training_data_util import DataWriter, TableReader

parser = ArgumentParser(usage=__doc__)
parser.add_argument('input', help='Source file.')
parser.add_argument(
	'output',
	help='Destination directory for read pages.'
)
parser.add_argument(
	'--force',
	action='store_true',
	default=False,
	help='Overwrite existing files.'
)


if __name__ == '__main__':
	args = parser.parse_args()

	table_reader = TableReader(args.input)
	table_reader.read()
	writer = DataWriter(args.output, table_reader, force_write=args.force)
	writer.write()
