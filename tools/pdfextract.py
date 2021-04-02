# Tools for extracting list of words from PDF which can be used in spell checking of ColorEditor

import fitz  # this is pymupdf
import re
import json
import argparse
import itertools

parser = argparse.ArgumentParser()
parser.add_argument('-f','--file', nargs='+', help='input files', required=True)
args = parser.parse_args()
files = args.file
print(files)

wordset = []
for pdffile in files:
    with fitz.open(pdffile) as doc:
        for i, page in enumerate(doc):
            print("parsing page "+str(i+1)+" in "+str(pdffile))
            text = page.getText()
            rst = list(set([x.group().lower() for x in re.finditer( r'([a-zA-Z]{3,})', text)]))
            wordset = itertools.chain(wordset, rst)
print("preparing data for final dumping")            
wordset = list(set(wordset))
wordset.sort()

print("dumping file....")
with open("english_word_list.js", "w") as outfile:
    val = "var english_word_list = "+json.dumps(wordset, indent=4)+";"
    outfile.write(val)
