'''
Created on May 07, 2018
 
@author: SDH
'''

import cast.application
import logging
import ast
from cast.analysers import CustomObject,Bookmark,create_link,external_link
from cast.application import ReferenceFinder
import re

#import re
#from cast.application.internal import application
#from cast.application import ApplicationLevelExtension
#import datetime
#from cast.analysers import log

class ColdFusionExtension(cast.application.ApplicationLevelExtension):

    def end_application(self, application):
        CFInsertUpdate_Tables_List = []
        CFStored_Proc_List = []
        logging.info("Inside Application...")
        self.intermediate_file_CFInsertUpdate = self.get_intermediate_file('CFInsertUpdate_Table_Links.txt')
        #logging.info(self.intermediate_file_CFInsertUpdate)
        #logging.info(self._get_intermediate_file_pathes('CFInsertUpdate_Table_Links.txt'))
        #logging.info("CFInsertUpdate_Table_Links.txt..")
        for line in self.get_intermediate_file('CFInsertUpdate_Table_Links.txt'):
            #logging.info("get_intermediate_file.." + str(line))
            CFInsertUpdate_Tables_List.append(ast.literal_eval(line))
        
        for line_table in self.get_intermediate_file('CFStoredProc_Table_Links.txt'):
            #logging.info("CFStoredProc_Table_Links.txt.." + str(line_table))
            CFStored_Proc_List.append(ast.literal_eval(line_table))

        ColdFusionExternalLinks.InvokeWebMethodAndComponentLinking(self,application,'CFInvokeProperties')
        ColdFusionExternalLinks.CFUpdateInsertTablesLinking(self,application,CFInsertUpdate_Tables_List)
        ColdFusionExternalLinks.CFStoredProcLinking(self,application,CFStored_Proc_List)
        ColdFusionExternalLinks.CFPatternLinking(self, application)

    pass

    
class ColdFusionExternalLinks():
    
    def InvokeWebMethodAndComponentLinking(self,application,invokeproperties):
        logging.info("InvokeWebMethodAndComponentLinking@@@")
        invokelist = list(application.search_objects(category=invokeproperties, load_properties= True))
        
        logging.info("invokelist.." + str(invokelist))
        if len(invokelist) > 0:
            for invokeobject in invokelist:
                webservice_name = invokeobject.get_property('CFInvokeProperties.InvokeWebserviceName')
                method_name = invokeobject.get_property('CFInvokeProperties.InvokeMethodName')
                webobj = invokeobject.get_property('CFInvokeProperties.WebService')
                #webcompList = list(application.search_objects(category='CFWebService',load_properties=True))
                parent = invokeobject
                logging.debug("Parent in InvokeWebMethodAndComponentLinking..   " + str(parent))
                
                child = None
                
                if webservice_name is not None:
                    webcompList = list(application.search_objects(category='CFWebService',load_properties=True))
                    #logging.debug("CFWebservice..   " + str(webcompList))
                    #logging.info("Webservice Name found.." + str(webobj))
                    #logging.info("method_name found.." + str(method_name))
                    for childobj in webcompList:
                        logging.debug('childobj...  ' +str(childobj))
                        child = childobj                
                        logging.debug("webcomponentlist.." + str(child))
                        break
                    if parent and child is not None:
                        #logging.info("Child not none")
                        #logging.info("Parent Child in CFInvoke.." + str(parent) + "----" + str(child))
                        cast.application.create_link("callLink", parent, child);  
                        logging.info("CFInvoke Link Created")            
                    
                elif method_name is not None:
                    method_name = "cfcomponent."+ method_name
                    #logging.info("### method_name@@@   " + str( method_name))
                    componentlist = list(application.search_objects(category='CFComponent', load_properties=True))
                    logging.debug("componentlist.." + str(componentlist))
                    for childobject in componentlist:
                        if childobject.get_name() == method_name:
                            child = childobject
                            #logging.info("Child 222 obj" + str(child))
                            break 
                    if parent and child :
                        #logging.info("Child not none")
                        #logging.info("Parent Child in CFCOMPONENT.." + str(parent) + "----" + str(child))
                        cast.application.create_link("callLink", parent, child);  
                        logging.info("CFCOMPONENT Link Created")                  
        pass
    
    def CFUpdateInsertTablesLinking(self,application,CFUpdateInsert_Tables_List):
        for items in CFUpdateInsert_Tables_List:
            logging.info("CFUpdateInsertTablesLinking")
            parent_type = items[0];
            parent_name = items[1];
            table_name = items[2];
            child = None 
            #logging.info("parent_type.. " + str(parent_type)) 
            #logging.info("parent_name" + str(parent_name))
            #logging.info("table name.." + str(table_name))  
            parentlist = list(application.search_objects(category=parent_type, name = parent_name, load_properties=False))
            #logging.info("parentlist" + str(parentlist))
            for parentobject in parentlist:
                if parentobject.get_name() == parent_name:
                    parent = parentobject
                    break
                    
            tableslist = list(application.search_objects(category='CAST_Oracle_RelationalTable', name=table_name, load_properties=False))
            #logging.info("tableslist" + str(tableslist))
            for tableobject in tableslist:
                #logging.info("Table Objects...CFUpdateInsertTablesLinking.." + str(tableobject.get_name))
                if tableobject.get_name() == table_name:
                    child = tableobject
                    logging.info("Child 333 obj" + str(child))
                    break
                
            if parent and child is not None:
                cast.application.create_link("useSelectLink", parent, child);  
                logging.info("Link Created for Oracle table")  

        pass
    
    def CFStoredProcLinking(self,application,CFStored_Proc_List):
        for items in CFStored_Proc_List:
            parent_type = items[0];
            parent_name = items[1];
            proc_name = items[2];
            child = None  
            parent = None
            #logging.info("Porc Name inside CFStoredProcLinking.." + str(proc_name))             
            parentlist = list(application.search_objects(category=parent_type, load_properties=False))
            #logging.info("CFStoredProcLinking.. parentlist" + str(parentlist))
            for parentobject in parentlist:
                if parentobject.get_name() == parent_name:
                    parent = parentobject
                    #logging.info("Parent Found for Proc--> " + str(parent))
                    break
                    
            procedurelist = list(application.search_objects(category='CAST_Oracle_Procedure', name=proc_name, load_properties=False))
            #logging.info("CFStoredProcLinking.. proclist.." + str(procedurelist))
            for procobject in procedurelist:
                if procobject.get_name() == proc_name:
                    child = procobject
                    break
              
            if parent and child:
                #logging.info("Parent.." + str(parent) + "Child.." + str(child))  
                cast.application.create_link("callLink", parent, child);
                logging.info("Proc Link Created")    
        pass
    
    def CFPatternLinking(self, application):
        ''' Link ColdFusion objects based on pattern. 
        
            See links element in ColdFusionLanguagePattern.xml. InvokeWebMethodAndComponentLinking already provides the support of links from cfinvoke objects.
        '''
        logging.info('Creating links based on patterns')
        
        patterns = {'methodCall': (r'methodcall\s*=\s*"(\w+)', 'callLink'),
                    'dotNameCall': (r'\.+(\w+)', 'callLink'),
                    'slashNameCall': (r'/([a-zA-Z_\x7f-\xff][\w.\x7f-\xff]*)', 'callLink')}
        application_objects = [ application_object for application_object in application.objects()]
        prefixes = {'CFComponent': 'cfcomponent.',
                    'CFMail': 'cfmail.',
                    'CFQuery': 'cfquery.',
                    'CFInvoke': 'cfinvoke.',
                    'CFFile': 'cffile.',
                    'CFFTP': 'cfftp.',
                    'CFHttp': 'cfhttp.',
                    'CFFunction': 'cffunction.',
                    'CFWebService': 'cfwebservice.'}

        linksReferenceFinder = ReferenceFinder()
        for pn, pd in patterns.items():
            linksReferenceFinder.add_pattern(pn, '', pd[0], '')
        for f in application.get_files():
            logging.info('Searching for references in %s', f.get_path())
            for reference in linksReferenceFinder.find_references_in_file(f):
                # Using logging.info for inestigations
                # logging.debug('Reference found: %s', reference.value)
                logging.info('Reference found: %s', reference.value)
                callee_name = re.sub(patterns[reference.pattern_name][0], r'\1', reference.value)
                # Using logging.info for inestigations
                # logging.debug('Callee name: %s', callee_name)
                logging.info('Callee name: %s', callee_name)
                for application_object in application_objects :
                    if application_object.get_type() in prefixes:
                        calle_name_with_prefix = prefixes[application_object.get_type()] + callee_name
                    else:
                        callee_name_with_prefix = callee_name
                    if application_object.get_name() == callee_name_with_prefix:
                        logging.info('Creating link between %s(%s) and %s(%s)', 
                                     reference.object.get_fullname(), 
                                     reference.object.get_type(),
                                     application_object.get_fullname(),
                                     application_object.get_type())
                        cast.application.create_link(patterns[reference.pattern_name][1], 
                                                reference.object, 
                                                application_object, 
                                                reference.bookmark)
    
if __name__ == '__main__':
    pass
