'''
Created on May 07, 2018
 
@author: SDH
'''

import hashlib
from cast.analysers import log
import cast.analysers.log as CAST
from html.parser import HTMLParser
from cast.analysers import Bookmark
from bs4 import BeautifulSoup
from lxml import etree as et
import re
from sqlalchemy.orm import query

class CastOperation():
    
    def __init__(self):
        dict = {}
        self.tag_names = []
        self.cf_file_data = {}
        self.component_tag_data = {}
        self.check_sum_with_commented_lines = ""
        self.check_sum_without_commented_lines = "" 
        self.bookmarks = []
        self.stack_line=[]
        self.stack_column=[]
        self.start_line_no = 0
        self.start_column_no =0
        self.end_line_no =0
        self.end_column_no =0
        
    def castParserColdFusion(self,file,filename):
        with open(filename) as fp:
            soup = BeautifulSoup(fp,'html.parser')
            return soup
        
        try:
            up = soup.find('i').parent
        except AttributeError:
            log.debug("Error !!!")
        # no <i> element
            
    def fileLoc(self,filename):
        md5_data_with_commented_lines = hashlib.md5()
        md5_data_without_commented_lines = hashlib.md5()
        line_of_code =0
        line_of_comments = 0
        no_of_blank_lines = 0
        flag = 0
        with open(filename,encoding='ISO_8859_1') as source_file:
        #with open(filename,'r') as source_file:
            for line  in source_file:
                if flag == 1:
                    md5_data_with_commented_lines.update(line.encode('ISO_8859_1'))
                    #md5_data_with_commented_lines.update(line.encode('utf-8'))
                    if line.find('-->')==-1:
                        line_of_comments = line_of_comments + 1
                    else:
                        line_of_comments = line_of_comments + 1
                        flag = 0
                else:
                    if len(line) == 1:
                        no_of_blank_lines =no_of_blank_lines + 1
                    elif line.find('<!--')!=-1:
                        md5_data_with_commented_lines.update(line.encode('ISO_8859_1'))
                        #md5_data_with_commented_lines.update(line.encode('utf-8'))
                        
                        line_of_comments = line_of_comments + 1
                        flag = 1
                        if line.find('-->')!=-1 and line.find('-->') > line.find('<!--'):
                            flag =0
                    else:
                        #md5_data_with_commented_lines.update(line.encode('utf-8'))
                        #md5_data_without_commented_lines.update(line.encode('utf-8'))
                        md5_data_with_commented_lines.update(line.encode('ISO_8859_1'))
                        md5_data_without_commented_lines.update(line.encode('ISO_8859_1'))
                        line_of_code = line_of_code +1
        self.check_sum_with_commented_lines = str(md5_data_with_commented_lines.hexdigest())
        self.check_sum_without_commented_lines = str(md5_data_without_commented_lines.hexdigest())  
        return [line_of_comments,line_of_code]

        def fileChecksum(self,filename):
            return [self.check_sum_with_commented_lines,self.check_sum_without_commented_lines]
            pass