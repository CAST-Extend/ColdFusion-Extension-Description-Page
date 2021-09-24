'''
Created on May 07, 2018
 
@author: SDH
'''
import os
import cast.analysers.ua
from cast.analysers import log
import logging
from cast.analysers import CustomObject, Bookmark, create_link, external_link
from Parser import CastOperation
from os.path import basename, splitext
from builtins import str
import binascii
import sqlparse
from sqlparse.sql import IdentifierList, Identifier, Where, Comparison, Parenthesis
from sqlparse.tokens import Keyword, DML
import re
import cast.application


class ColdFusionExtension(cast.analysers.ua.Extension):
    
    def _init_(self):
        log.debug("Init..")
        logging.info("Init..")
        print("Init..")
        self.filename = ""
        self.name = ""
        self.file_fullname = ""
        self.cftemplate_fullname = "" 
        self.cfcomponent_fullname = "" 
        self.file = ""    
        self.cf_data = ""  
        self.cfWebService_List = []    
        self.valid_tags_list = ['cfcomponent', 'cffunction', 'cfquery', 'cfinvoke', 'cffile', 'cfftp', 'cfhttp', 'cftemplate']
        pass
    
    def start_analysis(self):
        log.debug("Inside start_analysis")
        logging.info("Inside start_analysis")
        self.intermediate_file_CFInsertUpdate = self.get_intermediate_file("CFInsertUpdate_Table_Links.txt")
        self.intermediate_file_CFStoredProc = self.get_intermediate_file("CFStoredProc_Table_Links.txt")
        log.debug("Inside start_analysis -- self.intermediate_file_CFInsertUpdate" + str(self.intermediate_file_CFInsertUpdate))
        logging.info("Inside start_analysis -- self.intermediate_file_CFInsertUpdate" + str(self.intermediate_file_CFInsertUpdate))
        pass
     
    def start_file(self, file):
        self.file = file
        self.filename = file.get_path()
        # file_ref = open(self.filename,encoding='UTF_8')
        file_data = []
        with open(self.filename, 'r') as file_ref:
            for child in file_ref:
                try:
                    child = child.replace("\n", "")
                    file_data.append(child)
                except Exception as e:
                    import traceback
                    e = traceback.format_exc(e)
   
        parser = CastOperation()
        
        #----------------------------------------Creating CFComponent Objects and also links------------------------------
        if (self.filename.endswith(".cfc")):
            try :
                    index = self.filename.rfind('\\')
                    self.name = self.filename[index + 1:]
            except:
                    index = -1
             
            base = basename(self.name)
            # self.cfcomponent_fullname = self.filename+".CFComponent."+splitext(base)[0] 
            self.cfcomponent_fullname = self.filename + splitext(base)[0] 
            log.debug("cfcomponent_fullname-->" + str(self.cfcomponent_fullname))
            self.file_fullname = self.cfcomponent_fullname      
            CFComponent = CustomObject()
            self.saveObject(CFComponent, self.name, self.cfcomponent_fullname, "ColdFusion_CFC", file, self.cfcomponent_fullname)
            CFComponent.save()
            CFComponent.save_position(Bookmark(file, 1, 1, -1, -1))
            checksum = self.getcrc("\n".join(file_data))
            CFComponent.save_property('checksum.CodeOnlyChecksum', checksum)
            CFComponent.save_property('metric.CodeLinesCount', 0)
            CFComponent.save_property('metric.LeadingCommentLinesCount', 0)
            CFComponent.save_property('metric.BodyCommentLinesCount', 0)
            self.createInternalLinks(file, CFComponent, self.cfcomponent_fullname)
            pass
        # pass
        #----------------------------------------Creating CFTemplate Objects and also links------------------------------
        if (self.filename.endswith(".cfm")):
            try :
                    index = self.filename.rfind('\\')
                    self.name = self.filename[index + 1:]
            except:
                    index = -1
             
            base = basename(self.name)
            # self.cftemplate_fullname = self.filename+".CFTemplate."+splitext(base)[0]
            self.cftemplate_fullname = self.filename + splitext(base)[0]   
            log.debug("self.cftemplate_fullname->" + str(self.cftemplate_fullname))
            self.file_fullname = self.cftemplate_fullname       
            CFTemplate = CustomObject()
            self.saveObject(CFTemplate, self.name, self.cftemplate_fullname, "ColdFusion_CFM", file, self.cftemplate_fullname)
            CFTemplate.save()
            CFTemplate.save_position(Bookmark(file, 1, 1, -1, -1))
            checksum = self.getcrc("\n".join(file_data))
            CFTemplate.save_property('checksum.CodeOnlyChecksum', checksum)
            CFTemplate.save_property('metric.CodeLinesCount', 0)
            CFTemplate.save_property('metric.LeadingCommentLinesCount', 0)
            CFTemplate.save_property('metric.BodyCommentLinesCount', 0)
            self.createInternalLinks(file, CFTemplate, self.cftemplate_fullname)
            pass
            
        pass
    
    def start_type(self, _type):        
        self.intermediate_file_CFInsertUpdate.write(_type.get_fullname() + '\n')
        self.intermediate_file_CFStoredProc.write(_type.get_fullname() + '\n')
        
    def getcrc(self, text, initial_crc=0):
        return binascii.crc32(bytes(text.lower(), 'UTF-8'), initial_crc) - 2 ** 31
      
    def createInternalLinks(self, file, parent, parentfullname,):
        log.debug("Inside createInternalLinks *** ")
        logging.info("Inside createInternalLinks *** ")
        obj_parentNameFinal = None
        parser = CastOperation()
        cf_data = parser.castParserColdFusion(file, self.filename)   
        valid_tags_list = ['[document]', 'cfcomponent', 'cftemplate', 'cffunction', 'cfquery', 'cfinvoke', 'cffile', 'cfftp', 'cfhttp', 'cfupdate', 'cfinsert', 'cfstoredproc', 'cfmail']
        type_dict = {'cfcomponent':'CFComponent',
                     'cftemplate':'CFTemplate',
                     'cffunction':'CFFunction',
                     'cfquery':'CFQuery',
                     'cfinvoke':'CFInvoke',
                     'cffile':'CFFile',
                     'cfftp':'CFFTP',
                     'cfhttp':'CFHttp',
                     'cfinsert':'CFTemplate',
                     'cfmail':'CFMail',
                     'cfwebservice':'CFWebService'}
        
        parentOBJ_List = [parent] 
        cfqueryObj_List = []
        guid_counter = 0
        cffunction_guid_counter = 0
        cfquery_guid_counter = 0
        cfinvoke_guid_counter = 0
        cfftp_guid_counter = 0
        cffile_guid_counter = 0
        cfhttp_guid_counter = 0
        cfmail_guid_counter = 0
        obj_parentTagName = ''
        self.cf_Var = set([])
        self.cffunction_Var = set([])
        # cf_Var = set([])
        cf_list = []
        for child in cf_data.recursiveChildGenerator():
            # log.debug(">----child----< : ")
            # cf_Var = set([])
            undefined_parentCounter = 0
            undefined_childCounter = 0
            name = getattr(child, "name", None)
            # log.debug("Child name attr... " + str(name))
            if name is not None:
                
                chd_obj_name = None
                obj_name = None 
                obj_parentName = None
                # log.debug("name is not none--< " + name)
                # logging.info("name is not none--< " + name)
                if name in valid_tags_list:
                    # guid_counter = guid_counter + 1
                    obj_tagname = name
                    obj_name = child.get('name')
                    if obj_name is None:
                        undefined_childCounter = undefined_childCounter + 1
                        obj_name = "Undefined"  # +str(undefined_childCounter)
                        log.debug('Child Obj Name  ' + str(obj_name))
                    # log.debug("child_name-- > from tag list  " + obj_name)
                    # logging.info("child_name-- > " + obj_name)
                    # log.debug("paret ppppppppppppppp " + str(child.parent))
                    for p in child.parents:
                        # log.debug("paent list while parsing --- (((( "+ p.name)
                        if p.name in valid_tags_list and p.name == 'cfcomponent':
                            obj_parentTagName = p.name
                            obj_parentName1 = p.get('displayname')
                            obj_parentName = str(obj_parentName1).replace(" ", "")
                            if obj_parentName1 is None:
                                log.debug("obj NONE")
                                undefined_parentCounter = undefined_parentCounter + 1
                                obj_parentName = "Undefined"  # +str(undefined_parentCounter)
                                # obj_parentNameFinal = obj_parentTagName+"."+obj_parentName
                                # break
                            obj_parentNameFinal = obj_parentTagName + "." + obj_parentName
                            log.debug("parent name -- > from tag list   cfcomponent " + str(obj_parentNameFinal))
                            # break
                        # pass
                        if p.name in valid_tags_list and p.name in ('cftemplate', 'cffunction', 'cfquery', 'cfinvoke', 'cffile', 'cfftp', 'cfhttp', 'cfupdate', 'cfinsert', 'cfstoredproc', 'cfmail'):
                        # elif p.name in valid_tags_list and p.name is not None:   
                            obj_parentTagName = p.name
                            obj_parentName = p.get('name')
                            
                            if obj_parentName is None:
                                log.debug("obj NONE")
                                undefined_parentCounter = undefined_parentCounter + 1
                                obj_parentName = "Undefined"  # +str(undefined_parentCounter)
                                # break 
                            obj_parentNameFinal = obj_parentTagName + "." + obj_parentName
                            log.debug("parent name -- > from tag list   " + str(obj_parentNameFinal))
                            # break
                            # pass
                        # pass                    
                                                     
                    log.debug("parent name-->1111  " + str(obj_parentNameFinal) + "--> childname-->1111  " + str(obj_tagname) + "." + str(obj_name))
                
                    if name == 'cfcomponent' and child.parent.name == '[document]':
                        cfcomp_obj_name1 = child.get('displayname')
                        if cfcomp_obj_name1 is None:
                            undefined_childCounter = undefined_childCounter + 1
                            cfcomp_obj_name1 = "Undefined"
                            # break
                            # log.debug("cfcomp_obj_name Undefined" + str(cfcomp_obj_name1))
                                      
                        # log.debug("cfcomp_obj_name-->" + str(cfcomp_obj_name1))  
                        cfcomp_obj_name = str(cfcomp_obj_name1).replace(" ", "") 
                          
                        # log.debug("cfcomp_obj_name-->" + str(cfcomp_obj_name))
                        # break
                        # log.debug("creating objects of parent -- > "+ self.file + " child ->" + child.name)
                        cfcomponent = CustomObject()
                        # log.debug("Component Obj name... " + str(cfcomp_obj_name))
                        cfcomponent.set_name("cfcomponent." + cfcomp_obj_name)
                        cfcomponent.set_type('CFComponent')
                        cfcomponent.set_parent(parent)
                        # cfcomponent.set_guid(self.file_fullname+"."+str(obj_parentNameFinal)+"."+"cfcomponent."+str(cfcomp_obj_name)+"."+str(guid_counter))
                        cfcomponent.save()
                        cfcomponent.save_position(Bookmark(file, 1, 1, -1, -1))
                        parentOBJ_List.append(cfcomponent)
                        # log.debug("Obj List... cfcomponent" + str(parentOBJ_List))
                        
                    elif name == 'cftemplate' and child.parent.name == '[document]':
                        cftemplate = CustomObject()
                        # log.debug("CFTemplate Obj name... " + obj_name)
                        cftemplate.set_name("cftemplate." + obj_name)
                        cftemplate.set_type('CFTemplate')
                        cftemplate.set_parent(parent)
                        # cftemplate.set_guid(self.file_fullname+"."+str(obj_parentNameFinal)+"."+"cftemplate."+obj_name+"."+str(guid_counter))
                        cftemplate.save()
                        cftemplate.save_position(Bookmark(file, 1, 1, -1, -1))
                        parentOBJ_List.append(cftemplate)
                        # log.debug("Obj List... cftemplate" + str(parentOBJ_List)) 
                    
                    elif child.name == 'cffunction' :                        
                       # log.debug("inside cffunction linking")
                        cffunction = CustomObject()
                        cffunction.set_name("cffunction." + obj_name)
                        cffunction.set_type('CFFunction')
                        for i in parentOBJ_List:
                            log.debug("parent object full ********* name--cffunction > " + i.name)
                            if obj_parentNameFinal == i.name:
                                cffunction.set_parent(i)
                                # log.debug("child name--> cffunction" + "cffunction"+"."+obj_parentNameFinal+"  linked to parent--> " + i.name)                                
                                break
                            else:
                                
                                cffunction.set_parent(parent)
                                log.debug("Cf Parent  " + str(cffunction.parent.name))
                                
                        key = self.file_fullname + "." + str(obj_parentNameFinal) + "." + "cffunction." + obj_name
                        
                        # log.debug("CF_VAR   " + str(cf_Var))
                        if key not in self.cffunction_Var:
                            cffunction.set_guid(key)
                            cffunction.save()
                            cffunction.save_position(Bookmark(file, 1, 1, -1, -1))
                            self.cffunction_Var.add(key)
                        # cffunction.set_guid(self.file_fullname + "." + str(obj_parentNameFinal) + "." + "cffunction." + obj_name + "." + str(guid_counter))
#                         log.debug("CFFUNCTION GUID == "+str(self.file_fullname+"."+str(obj_parentName)+"."+"cffunction."+obj_name+"."+str(guid_counter))
                           
                            parentOBJ_List.append(cffunction)
                            create_link("callLink", cffunction.parent, cffunction)
                            log.debug(" Link Created to CFFunction   " + str(cffunction.parent.name) + "  --to--  " + str(cffunction.name))
                        
                    elif child.name == 'cfquery':
                        cfquery_guid_counter = cfquery_guid_counter + 1
                        link_type = ""
                        log.debug("inside cfquery linking   " + str(child.get("name"))) 
                        tableList = []                       
                        sqlQuery = str(child.contents)
                        # log.debug("sqlQuery... " + str(sqlQuery))
                        executeSql1 = sqlQuery.replace('\\n', '').strip()
                        executeSql_t = executeSql1.replace('\\t', " ")
                        executeSql_x = executeSql_t.lstrip("['")
                        executeSql_y = executeSql_x.rstrip(']')
                        executeSql_2 = re.sub(' +', ' ', executeSql_y.strip().replace('"', ''))
                        executeSql_3 = executeSql_2.strip()
                        executeSql = executeSql_3.upper()
                        # log.debug("execute sql --- > " + executeSql)
                        # tableList = self.get_names_table(executeSql)
                        # log.debug("tableList.. " + str(tableList))
                        cfquery = CustomObject()
                        cfquery.set_name("cfquery." + obj_name)
                        cfquery.set_type('CFQuery')
                        # cfquery.set_type('CAST_SQL_NamedQuery')
                        for i in parentOBJ_List:
                            
                            #log.debug("i name in CFQuery  " + i.name)
                            if obj_parentNameFinal == i.name:
                                log.debug("CFQUERY  TRUE..." + str(obj_parentNameFinal))
                                cfquery.set_parent(i)   
                                # log.debug("child name--> " + "cfquery"+"."+obj_name+"  linked to parent--> " + i.name)
                                break
                            else:
                                log.debug("CFQUERY ELSE... " + str(parent.name))
                                cfquery.set_parent(parent)                             
                                
                        # cfquery.set_guid(self.file+obj_parentName+"cfquery."+obj_name+guid_counter)
                        log.debug("CFQUERY Parent  " + str(cfquery.parent.name))
                        # cf_Var.add(str(child.get("name")))
                        
                        key = self.file_fullname + "." + str(obj_parentNameFinal) + "." + "cfquery." + str(child.get("name"))
                        
                        # log.debug("CF_VAR   " + str(cf_Var))
                        if key not in self.cf_Var:
                            cfquery.set_guid(key)
                            cfquery.save()
                            cfquery.save_position(Bookmark(file, 1, 1, -1, -1))
                            self.cf_Var.add(key)
                        # log.debug("cfquery parent == "+str(cfquery.fullname))
                            create_link("callLink", cfquery.parent, cfquery)
                            log.debug("Link created --> Template/Function to cfquery" + str(cfquery.name))
                            # logging.info("Link created --> Template to cfquery")
                                                    
                            # cfquery.save_property("CAST_SQL_MetricableQuery.CFQuery", executeSql)
                            log.debug("cfquery objects " + str(cfquery.name))
                            
                            for embedded in external_link.analyse_embedded(executeSql): 
                                for t in embedded.types: 
                                    create_link(t, cfquery, embedded.callee)
                            log.debug("Link Created between CfQuery and table..")              
                        parentOBJ_List.append(cfquery)
                        # cfqueryObj_List.append(cfquery)                 
                    elif child.name == 'cfinvoke':
                        cfinvoke_guid_counter = cfinvoke_guid_counter + 1
                        cfinvoke_obj_name = child.get('method')
                        # log.debug("inside cfinvoke linking == "+str(cfinvoke_obj_name))
                        CFInvoke = CustomObject()
                        CFInvoke.set_name("cfinvoke." + cfinvoke_obj_name)
                        CFInvoke.set_type('CFInvoke')
                        for i in parentOBJ_List:
                            # log.debug("parent object full ********* name-- > cfinvoke"+ i.fullname)
                            if obj_parentNameFinal == i.name:
                                CFInvoke.set_parent(i)
                                # log.debug("child name--> " + "cfinvoke"+"."+cfinvoke_obj_name+"  linked to parent--> " + i.name)
                                break
                            else:
                                CFInvoke.set_parent(parent)
                        # CFInvoke.set_guid(self.file+obj_parentName+"cfinvoke."+obj_name+guid_counter)
                        # CFInvoke.set_guid(self.file_fullname + "." + str(obj_parentNameFinal) + "." + "cfinvoke." + obj_name + "." + str(cfinvoke_guid_counter))
                        CFInvoke.set_guid(self.file_fullname + "." + str(obj_parentNameFinal) + "." + "cfinvoke." + obj_name)
                        CFInvoke.save()
                        CFInvoke.save_position(Bookmark(file, 1, 1, -1, -1))
                        parentOBJ_List.append(CFInvoke) 
                        create_link("callLink", CFInvoke.parent, CFInvoke)
                        
                        if(child.get('webservice') is not None):
                            webservicename = child.get('webservice')
                            # log.debug("ZZ == "+str(webservicename))
                            CFInvoke.save_property('CFInvokeProperties.InvokeWebserviceName', webservicename)
                            if webservicename is not None:
                                    CFWebservice = CustomObject()
                                    CFWebservice.set_name("cfwebservice." + webservicename)
                                    CFWebservice.set_type('CFWebService')
                                    CFWebservice.set_parent(parent)
                                    CFWebservice.set_guid(self.file_fullname + "." + str(obj_parentNameFinal) + "." + "cfwebservice." + obj_name + "." + str(cfinvoke_guid_counter))
                                    CFWebservice.save()
                                    log.debug("CFWebService OBJ..." + str(CFWebservice.fullname))
                                    CFInvoke.save_property('CFInvokeProperties.WebService' , str(CFWebservice))                              
                                    pass
                        if(child.get('method') is not None):
                            methodname = child.get('method')
                            # log.debug("XXa == "+str(methodname))
                            CFInvoke.save_property('CFInvokeProperties.InvokeMethodName', methodname)                            
                    
                    elif child.name == 'cffile':
                        cffile_guid_counter = cffile_guid_counter + 1                        
                        cffile_obj_name = child.get('action')
                        log.debug("inside cffile linking")
                        cffile = CustomObject()
                        cffile.set_name("cffile." + cffile_obj_name)
                        cffile.set_type('CFFile')
                        for i in parentOBJ_List:
                            # log.debug("parent object full ********* name-- >cffile"+ i.fullname)
                            if obj_parentNameFinal == i.name:
                                cffunction.set_parent(i)
                                # log.debug("child name--> " + "cffile"+"."+cffile_obj_name+"  linked to parent--> " + i.name)
                                break
                            else:
                                cffile.set_parent(parent)
                        cffile.set_guid(self.file_fullname + "." + str(obj_parentNameFinal) + "." + "cffile." + obj_name + "." + str(cffile_guid_counter))
                        cffile.save()
                        cffile.save_position(Bookmark(file, 1, 1, -1, -1))
                        parentOBJ_List.append(cffile)
                        create_link("callLink", cffile.parent, cffile)
                        
                    elif child.name == 'cfftp':
                        cfftp_guid_counter = cfftp_guid_counter + 1
                        cfftp_obj_name = child.get('action')
                        # log.debug("inside cfftp linking")
                        cfftp = CustomObject()
                        cfftp.set_name("cfftp." + cfftp_obj_name)
                        cfftp.set_type('CFFTP')
                        for i in parentOBJ_List:
                            # log.debug("parent object full ********* name-- >cfftp"+ i.fullname)
                            if obj_parentNameFinal == i.name:
                                cfftp.set_parent(i)
                                # log.debug("child name--> " + "cfftp"+"."+cfftp_obj_name+"  linked to parent--> " + i.name)
                                break
                            else:
                                cfftp.set_parent(parent)
                        cfftp.set_guid(self.file_fullname + "." + str(obj_parentNameFinal) + "." + "cfftp." + obj_name + "." + str(cfftp_guid_counter))
                        cfftp.save()
                        cfftp.save_position(Bookmark(file, 1, 1, -1, -1))
                        parentOBJ_List.append(cfftp)
                        create_link("callLink", cfftp.parent, cfftp)
                        
                    elif child.name == 'cfhttp':
                        cfhttp_guid_counter = cfhttp_guid_counter + 1
                        cfhttp_obj_name = child.get('method')
                        # log.debug("inside cfhttp linking")
                        cfhttp = CustomObject()
                        cfhttp.set_name("cfhttp." + cfhttp_obj_name)
                        cfhttp.set_type('CFHttp')
                        for i in parentOBJ_List:
                            # log.debug("parent object full ********* name--cfhttp > "+ i.fullname)
                            if obj_parentNameFinal == i.name:
                                cfhttp.set_parent(i)
                                # log.debug("child name--> " + "cfhttp"+"."+cfhttp_obj_name+"  linked to parent--> " + i.name)
                                break
                            else:
                                cfhttp.set_parent(parent)
                        cfhttp.set_guid(self.file_fullname + "." + str(obj_parentNameFinal) + "." + "cfhttp." + obj_name + "." + str(cfhttp_guid_counter))
                        cfhttp.save()
                        cfhttp.save_position(Bookmark(file, 1, 1, -1, -1))
                        parentOBJ_List.append(cfhttp)
                        create_link("callLink", cfhttp.parent, cfhttp)
                        
                    elif child.name == 'cfmail':
                        cfmail_guid_counter = cfmail_guid_counter + 1
                        cfmail_obj_name = child.get('method')
                        # log.debug("CFMail OBJ... " + str(cfmail_obj_name))
                        # log.debug("inside cfmail linking")
                        cfmail = CustomObject()
                        cfmail.set_name("cfmail." + str(cfmail_obj_name))
                        cfmail.set_type('CFHttp')
                        for i in parentOBJ_List:
                            # log.debug("parent object full ********* name--cfmail > "+ i.fullname)
                            if obj_parentNameFinal == i.name:
                                cfmail.set_parent(i)
                                # log.debug("child name--> " + "cfhttp"+"."+cfhttp_obj_name+"  linked to parent--> " + i.name)
                                break
                            else:
                                cfmail.set_parent(parent)
                        # cfhttp.set_guid(self.file+obj_parentName+"cfhttp."+obj_name+guid_counter)
                        cfmail.set_guid(self.file_fullname + "." + str(obj_parentNameFinal) + "." + "cfmail." + obj_name + "." + str(cfmail_guid_counter))
                        cfmail.save()
                        cfmail.save_position(Bookmark(file, 1, 1, -1, -1))
                        parentOBJ_List.append(cfmail)
                        create_link("callLink", cfmail.parent, cfmail)
                        log.debug('CFMail link created')
                                          
                    elif child.name in ('cfupdate', 'cfinsert'):
                        log.debug("inside cfInsert linking")
                        table_name = child.get('tablename')
                        # log.debug("XXXXXXXXXXXXXXXXXXXXXXXXX == "+str(table_name))
                        # log.debug("Parent Obj...>>> insert--->   " + str(obj_parentTagName))
                        obj_parent_type = type_dict.get(obj_parentTagName)
                        # log.debug("obj_parent_type -->>cfupdate/insert"+str(obj_parent_type))
                        link_table_data = [obj_parent_type, obj_parentNameFinal, table_name]
                        # log.debug("update/insert table data..." + str(link_table_data))
                        self.intermediate_file_CFInsertUpdate.write(str(link_table_data) + '\n')

                    elif child.name in ('cfstoredproc'):
                        log.debug("inside cfstoredproc linking")
                        proc_name = child.get('procedure')
                        # log.debug("ZZZZZZZZZZZZZZZZZZZZZZZ == "+str(proc_name))
                        # log.debug("Parent Obj...>>> procedure." + str(obj_parentTagName))
                        obj_parent_type = type_dict.get(obj_parentTagName)
                        # log.debug("obj_parent_type -- storproc>> "+str(obj_parent_type))
                        link_proc_data = [obj_parent_type, obj_parentNameFinal, proc_name]
                        self.intermediate_file_CFStoredProc.write(str(link_proc_data) + '\n')    
                    
#                     else:
#                         log.debug("No Valid Tags..")
#                         continue 
                             
            elif not child.isspace() is not None:
                log.debug("It is child node-- > " + child.name)
            # log.debug("CF_VAR FINAL   " + str(self.cf_Var))
                # pass
#         log.debug("*** intermediate_file_CFInsertUpdate  **** " + str(self.intermediate_file_CFInsertUpdate))
#         logging.info("*** intermediate_file_CFInsertUpdate  **** " + str(self.intermediate_file_CFInsertUpdate))
#         log.debug("*** intermediate_file_CFStoredProc *** " + str(self.intermediate_file_CFStoredProc))
#         logging.info("*** intermediate_file_CFStoredProc *** " + str(self.intermediate_file_CFStoredProc))
        pass     
    
    def get_names_table(self, sql_str):

        # remove the /* */ comments
        q = re.sub(r"/\*[^*]*\*+(?:[^*/][^*]*\*+)*/", "", sql_str)
    
        # remove whole line -- and # comments
        lines = [line for line in q.splitlines() if not re.match("^\s*(--|#)", line)]
    
        # remove trailing -- and # comments
        q = " ".join([re.split("--|#", line)[0] for line in lines])
    
        # split on blanks, parens and semicolons
        tokens = re.split(r"[\s)(;]+", q)
        log.debug("Tokens... " + str(tokens))
        # scan the tokens. if we see a FROM or JOIN, we set the get_next
        # flag, and grab the next one (unless it's SELECT).
    
        result = set()
        get_next = False
        for tok in tokens:
            if get_next:
                if tok.lower() not in ["", "select", "update", "insert", "delete"]:
                    result.add(tok)
                get_next = False
            get_next = tok.lower() in ["update", "from", "join", "into", "order", "group", "by", "having", "#TABLE#"]
            # log.debug("get_next   " + str(get_next))
            # result.add(tok)
        log.debug("Table:  " + str(result))
        return result

    def saveObject(self, obj_reference, name, fullname, obj_type, parent, guid):
        log.debug("save object--->")
        obj_reference.set_name(name)
        obj_reference.set_fullname(fullname)
        obj_reference.set_type(obj_type)
        obj_reference.set_parent(parent)
        obj_reference.set_guid(guid) 
        pass
   
    def end_file(self, file):
        pass   
    
    def end_analysis(self):       
        pass
