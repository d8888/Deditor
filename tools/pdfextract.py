# Tools for extracting list of words from PDF which can be used in spell checking of ColorEditor

import fitz  # this is pymupdf
import re
import json
import argparse
import itertools

maxPhraseWord = 4
minWordLen = 3

def checkKey(key):
    global minWordLen
    for elem in key:
        if len(elem)<minWordLen:
            return False
    return True

parser = argparse.ArgumentParser()
parser.add_argument('-f','--file', nargs='+', help='input files', required=True)
args = parser.parse_args()
files = args.file
print(files)


wordgroup = {}

for pdffile in files:
    with fitz.open(pdffile) as doc:
        for i, page in enumerate(doc):
            print("parsing page "+str(i+1)+" in "+str(pdffile))
            

            text = page.getText()
            rst = [x.group().lower() for x in re.finditer( r'([a-zA-Z]{1,})', text)]

            nword = len(rst)
            for k in range(0, nword):
                for j in range(1, maxPhraseWord):
                    if k+j>nword:
                        continue

                    slce = rst[k:k+j]
                    if not checkKey(slce):
                        continue
                    key = " ".join(slce).lower()
                    
                    if key not in wordgroup:
                        wordgroup[key]=0
                    wordgroup[key]+=1

            
print("preparing data for final dumping")            

wordset = []
for elem in wordgroup:
    nwords = len(elem.split())
    if nwords==1:
        wordset.append(elem.strip())
    elif nwords==2:
        if wordgroup[elem]>5:
            wordset.append(elem.strip())
    else:
        if wordgroup[elem]>2:
            wordset.append(elem.strip())

wordset = list(set(wordset))    
wordset.sort()

print("dumping file....")
with open("english_word_list.js", "w") as outfile:
    val = "var english_word_list = "+json.dumps(wordset, indent=4)+";"
    outfile.write(val)
