## Title: Coding Coursework Project___Part1 Python Codes
## Course: Advanced Quantitative Methods
## Author: Whitney Hung
## study program: PANC
## Date: 29/04/2019
## Program language: Python, version 3

################ Notes
## This is only preprocessing, and generates middle file named: outputData.csv
## For further processing please continue part 2 in R Studio.
## Make sure to delete same file name 'outputData.csv', when rerunning the program.
## Because it will append but not overwrite the existing file.
################ 

#____________________Code starts here

#Import packages

import copy
import csv
import json
import re
import os.path
from os.path import isfile, join
from os import listdir

# ____________________Read file

# Loop through 40 files
key1 = ['trialnum', 'cue1', 'cue2', 'cue3', 'cue4', 'outcome', 'resp_corr', 'response', 'RT']
key2 = ['subno', 'cbcond', 'map', 'format', 'cond']

onlyfiles = [f for f in listdir('.') if isfile(join('.', f)) and f[-4:] == '.DAT']
print(onlyfiles)
# for filename in onlyfiles:
    # print(filename)

# for w in range(1,41):
for w in range(1,1):

    filename = "./S"+ str(w) +".DAT"

    # Read in the data
    with open(filename) as fn:
        content = fn.readlines()
    content = [x.strip() for x in content]

    # Get rid of line spaces in AnoF
    content = list(filter(None, content))


    #____________________End of fomatting

    #____________________Data wrangling

    # Delete AnoF condition data
    x = content.index('AnoF          (Task Condition)')
    del content[x-1 : x + 69]

    # Delete 'Test data' line in the middle of the data values
    y = content.index('Test data (trial/4 log cues/resp choice 1or2/rtime)')
    del content[y]

    # Deal with data values 
    data = []
    for d in range(6,76):
        # print(content[d])
        data.append(content[d].split())

    # adding columns for each phase, so the structure is the same.
    for i in range(56):
        data[i].insert(7, 'NaN')
        # This is adding response for training phase
    for i in range(56,len(data)):
        data[i].insert(5, 'NaN')
        data[i].insert(5, 'NaN')
        # This is adding outcome and res_corr(this will be corrected in R) for testing phase


        #add key value pair to data, to create dictionary, add response(only exist in test phase)
    
    dat = []
    for i in range(len(data)):
        dat.append(dict(zip(key1,data[i])))
        # dat stands for the data values, type #list
        # key1 are the fields:['trialnum', 'cue1', 'cue2', 'cue3', 'cue4', 'outcome', 'resp_corr', 'response', 'RT']
        # This is adding data to the variable names(fields)

    # Deal with variable labels & sub, condition, information
    titles = []  
    for t in range(0,5):
        sep = ' '
        rest = content[t].split(sep, 1)[0]
        titles.append(rest) # ['s40', '4', '19', 'disease', 'FnoA']

    
    d = dict(zip(key2,titles))
        # d stands for the label values, type= dict

        # {'subno': 's40',
        #  'cbcond': '4',
        #  'map': '19',
        #  'format': 'disease',
        #  'cond': 'FnoA',
        #  'fields': {'trialnum': '70',
        #   'cue1': '0',
        #   'cue2': '0',
        #   'cue3': '0',
        #   'cue4': '1',
        #   'outcome': 'NaN',
        #   'resp_corr': 'NaN',
        #   'response': '2',
        #   'RT': '0.541'}}

    # Combine label and data into dictionary
    listofdictofsub = []

    for i in range(len(dat)):
        d['fields'] = dat[i]
        dd = copy.deepcopy(d)
        listofdictofsub.append(dd)

    # check output format
    # for item in listofdictofsub:
    #     print(item, '\n')


    #____________________write csv file

    x = json.dumps(listofdictofsub)
    
    #Get rid of symbols
    x = re.sub('%', '', x)

    #Load as json file
    x = json.loads(x)

    print(w)
    # This shows if it processes correctly.

    file_exists = os.path.isfile('outputData.csv') 

    with open("outputData.csv", "a", newline='') as f:
        fwriter = csv.writer(f)
        if not file_exists:
            fwriter.writerow(["subno", "cbcond", "map", "format", "cond", "trialnum", "cue1", "cue2", "cue3", "cue4", "outcome", "resp_corr", "response", "RT"])


        for x in x:
            fwriter.writerow([x["subno"],
                            x["cbcond"],
                            x["map"],
                            x["format"],
                            x["cond"],
                            x["fields"]["trialnum"],
                            x["fields"]["cue1"],
                            x["fields"]["cue2"],
                            x["fields"]["cue3"],
                            x["fields"]["cue4"],
                            x["fields"]["outcome"],
                            x["fields"]["resp_corr"],
                            x["fields"]["response"],
                            x["fields"]["RT"]])
        

