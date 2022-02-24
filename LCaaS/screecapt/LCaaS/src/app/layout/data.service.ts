import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { mapChildrenIntoArray } from '@angular/router/src/url_tree';
import { map, catchError, tap } from 'rxjs/operators';
import { ERROR_COMPONENT_TYPE } from '@angular/compiler';
import { environment } from '../../environments/environment';
const endpoint = environment.apiUrl;

// import * as myJson from '../../../environment/env.json';
// const endpoint = myJson.host;
// const hostname = window.location.hostname;
// const port = 5000;
// const routeLink = '/api/v1/'
// const protocol = window.location.protocol;
// const endpoint = protocol + '//' + hostname + ':' + port + routeLink;

// const endpoint = 'http://172.18.33.227:5003/api/v1/';
//  const endpoint = 'http://172.18.32.213:5009/api/v1/';
// const endpoint = 'http://localhost:5000/api/v1/';
// const endpoint = 'http://13.234.96.84:5000/api/v1/';
// const endpoint = 'https://lcaas.al.ge.com/python/api/v1/';

const httpOptions = {
  headers: new HttpHeaders({
    'Content-Type':  'application/json'
  })
};
const httpParam = new HttpParams();
@Injectable({
  providedIn: 'root'
})
export class DataService {
  ip = '13.234.96.84';
  port = 4100;
  constructor(private http: HttpClient) {
  }
  private extractData(res: Response) {
    const body = res;
    return body || { };
  }

  getMissingComponents(): Observable<any> {
    return this.http.get(endpoint  + 'missingComponents').pipe(
      map(this.extractData));
  }
  getMissingComponentsWithApp(option: string): Observable<any> {
    return this.http.get(endpoint  + 'missingComponents?option=' + option).pipe(
      map(this.extractData));
  }

  getChartDetails(): Observable<any> {
    return this.http.get(endpoint  + 'buisinessConnetedRules').pipe(
      map(this.extractData));
  }
  // getXRefDetails(searchFilter: string): Observable<any> {
  //   return this.http.get(endpoint + 'crossReference?searchFilter=' + searchFilter).pipe(
  //     map(this.extractData));
  // }
  generateDocument(option: string): Observable<any> {
    return this.http.get(endpoint + 'generateDocument?option=' + option).pipe(
      map(this.extractData)
    );
  }
  getXRefDetails(searchFilter: string, Download_flag: string): Observable<any> {
    // tslint:disable-next-line:max-line-length
    return this.http.get(endpoint + 'crossReference?searchFilter=' + searchFilter + '&overrideFilter=' + Download_flag).pipe(
      map(this.extractData));
  }

  getCICSXRefDetails(): Observable<any> {
    return this.http.get(endpoint + 'cicsxref').pipe(
      map(this.extractData));
  }
  getCICSXRefAppDetails(selectedApplication: string, searchFilter: string, flag: string): Observable<any> {
    return this.http.get(endpoint + 'cicsxrefApp?option=' + selectedApplication
      + '&searchFilter=' + searchFilter + '&flag=' + flag ).pipe(
      map(this.extractData));
  }
  getImpactDetails(searchFilter: string, Download_flag: string): Observable<any> {
    return this.http.get(endpoint + 'varImpact?searchFilter=' + searchFilter + '&overrideFilter=' + Download_flag).pipe(
      map(this.extractData));
  }
  getImpactSummaryDetails(searchFilter: string, Download_flag: string): Observable<any> {
    return this.http.get(endpoint + 'sumvarImpact?searchFilter=' + searchFilter + '&overrideFilter=' + Download_flag).pipe(
      map(this.extractData));
  }
  getXRefApplicationDetails(application: string, searchFilter: string, Download_flag: string): Observable<any> {
    // tslint:disable-next-line:max-line-length
    return this.http.get(endpoint + 'crossReferenceApplication?option=' + application + '&searchFilter=' + searchFilter + '&overrideFilter=' + Download_flag).pipe(
      map(this.extractData));
  }

  getRuleCategoryDetails(application: string, searchFilter: string, Download_flag: string): Observable<any> {
    // tslint:disable-next-line:max-line-length
    return this.http.get(endpoint + 'ruleCategory?option=' + application + '&searchFilter=' + searchFilter + '&overrideFilter=' + Download_flag).pipe(
      map(this.extractData));
  }

  getMasterInvenDetails(): Observable<any> {
    return this.http.get(endpoint + 'masterInventory').pipe(
      map(this.extractData));
  }
  getCicsScreenDetails(): Observable<any> {
    return this.http.get(endpoint + 'cicsfield').pipe(
      map(this.extractData));
  }
  getCicsScreenAppDetails(selectedApplication: string): Observable<any> {
    return this.http.get(endpoint + 'cicsfield?option=' + selectedApplication).pipe(
      map(this.extractData));
  }
  getMasterInvenDetailsWithApplicationFilter(component_type: string): Observable<any> {
    return this.http.get(endpoint + 'masterInventory?option=' + component_type).pipe(
      map(this.extractData));
  }
  getCRUDDetails(): Observable<any> {
    return this.http.get(endpoint + 'CRUD').pipe(
      map(this.extractData));
  }
  getCRUDDetailsWithApplication(option: string): Observable<any> {
    return this.http.get(endpoint + 'CRUD?option=' + option).pipe(
      map(this.extractData));
  }
  getMsgLogDetails(): Observable<any> {
    return this.http.get('http://localhost:5010/api/v1/' + 'MsgLog').pipe(
      map(this.extractData));
  }
  getOrphanDetails(): Observable<any> {
    return this.http.get(endpoint + 'orphanReport').pipe(
      map(this.extractData));
  }
  getOrphanDetailsWithApp(option: string): Observable<any> {
    return this.http.get(endpoint + 'orphanReport?option=' + option).pipe(
      map(this.extractData));
  }
  getCommentedLinesDetails(): Observable<any> {
    return this.http.get(endpoint + 'comment_line_report').pipe(
      map(this.extractData));
  }
  getCommentedLinesDetailsWithApp(option: string): Observable<any> {
    return this.http.get(endpoint + 'comment_line_report?option=' + option).pipe(
      map(this.extractData));
  }
  getDropImpactDetails(): Observable<any> {
    return this.http.get(endpoint + 'getDropImp').pipe(
      map(this.extractData));
  }
  getDropImpactDetailsWithApp(option: string): Observable<any>{
    return this.http.get(endpoint + 'getDropImp?option=' + option).pipe(
      map(this.extractData));
  }
  getDeadparaDetails(): Observable<any> {
    return this.http.get(endpoint + 'deadparalist').pipe(
      map(this.extractData));
  }
  getDeadparaDetailsWithApp(option: string): Observable<any> {
    return this.http.get(endpoint + 'deadparalist?option=' + option).pipe(
      map(this.extractData));
  }
  // spider chart get component name based on component type
  getBREDetails(): Observable<any> {
    return this.http.get(endpoint + 'bre').pipe(
      map(this.extractData));
  }
  getBREDetailsNew(component: string): Observable<any> {
   return this.http.get(endpoint + 'bre?option=' + component).pipe(
      map(this.extractData));
  }
  getBREDetailsNewFlag(component: string, overrideFilter:string): Observable<any> {
    return this.http.get(endpoint + 'bre?option=' + component+'&overrideFilter=' + overrideFilter).pipe(
       map(this.extractData));
   }
  getBREDetailsXref(component: string, searchFilter: string): Observable<any> {
    return this.http.get(endpoint + 'bre?option=' + component + '&searchFilter=' + searchFilter).pipe(
       map(this.extractData));
   }
  getBREPlSqlDetailsNew(type: string, list: string, pgmname: string): Observable<any> {
    return this.http.get(endpoint + 'breplsql?option=' + type + '&option1=' + list
    +'&option2=' + pgmname).pipe(
       map(this.extractData));
   }
   getBREPlSqlDetailsNewWithApp(type: string, list: string, pgmname: string, appname: string): Observable<any> {
    return this.http.get(endpoint + 'breplsql?option=' + type + '&option1=' + list
    +'&option2=' + pgmname + '&application_name=' + appname).pipe(
       map(this.extractData));
   }
   getBREPlSql2DetailsNew(type: string, list: string, pgmname: string): Observable<any> {
    return this.http.get(endpoint + 'breplsql2?option=' + type + '&option1=' + list
    +'&option2=' + pgmname).pipe(
       map(this.extractData));
   }
   getBREPlSql2DetailsNewWithApp(type: string, list: string, pgmname: string, appname: string): Observable<any> {
    return this.http.get(endpoint + 'breplsql2?option=' + type + '&option1=' + list
    +'&option2=' + pgmname + '&application_name=' + appname).pipe(
       map(this.extractData));
   }
  getCicsRulesDetails(component: string): Observable<any> {
    return this.http.get(endpoint + 'cicsrule?option=' + component).pipe(
       map(this.extractData));
   }

  getBREReportDetailsNew(component: string): Observable<any> {
    return this.http.get(endpoint + 'bre_2?option=' + component).pipe(
       map(this.extractData));
   }
   getBREReportDetailsNewFlag(component: string, overrideFilter:string): Observable<any> {
    return this.http.get(endpoint + 'bre_2?option=' + component + '&overrideFilter=' + overrideFilter).pipe(
       map(this.extractData));
   }
   getBREReportDetailsNewXRef(component: string, searchFilter: string): Observable<any> {
    return this.http.get(endpoint + 'bre_2?option=' + component + '&searchFilter=' + searchFilter ).pipe(
       map(this.extractData));
   }
   updateBREReportTrial(fragment_id: string, rule_description: string, rule_category: string): Observable<any> {
      console.log(endpoint + 'updateBRE?fragment_id=' + fragment_id +
      '&rule_description=' + rule_description + '&rule_category=' + rule_category);
  //  fragment_id, rule_description, rule_category
  return this.http.get(endpoint + 'updateBRE?fragment_id=' + fragment_id +
  '&rule_description=' + rule_description + '&rule_category=' + rule_category
  ).pipe(
     map(this.extractData));
 }
  //  updateBREReportNew(fragment_id: string, pgm_name: string, para_name: string,
  //     source_statements: string, rule_description: string,
  //     rule_category: string, Rule: string, rule_relation: string): Observable<any> {
  //       console.log(endpoint + 'updateBRE?fragment_id=' + fragment_id
  //       + '&pgm_name=' + pgm_name + '&para_name=' + para_name + '&source_statements=' + source_statements +
  //       '&rule_description=' + rule_description + '&rule_category=' + rule_category +
  //       '&Rule=' + Rule + '&rule_relation=' + rule_relation);
  //   //  fragment_id, pgm_name, para_name, source_statements, rule_description, rule_category, Rule, rule_relation
  //   return this.http.get(endpoint + 'updateBRE?fragment_id=' + fragment_id
  //   + '&pgm_name=' + pgm_name + '&para_name=' + para_name + '&source_statements=' + source_statements +
  //   '&rule_description=' + rule_description + '&rule_category=' + rule_category +
  //   '&Rule=' + Rule + '&rule_relation=' + rule_relation
  //   ).pipe(
  //      map(this.extractData));
  //  }
  getGlossaryDetails(): Observable<any> {
    return this.http.get(endpoint + 'glossary').pipe(
       map(this.extractData));
   }
   getGlossaryDetails_limit( Download_flag: string): Observable<any> {
    return this.http.get(endpoint + 'glossary?overrideFilter=' + Download_flag).pipe(
       map(this.extractData));
   }
   getGlossaryDetails_limit_app(selectedApplication:string, selectedComponent: string, Download_flag: string): Observable<any> {
    return this.http.get(endpoint + 'glossary?app_name='+selectedApplication+'&option='+ selectedComponent +'&overrideFilter=' + Download_flag).pipe(
       map(this.extractData));
   }
  getGlossaryDetailsXref(searchFilter: string, Download_flag: string): Observable<any> {
    return this.http.get(endpoint + 'glossary?searchFilter=' + searchFilter + '&overrideFilter=' + Download_flag).pipe(
       map(this.extractData));
   }
  updateVariableDefinition(): Observable<any> {
  return this.http.get(endpoint + 'updateVarDef').pipe(
      map(this.extractData));
  }
  updateVariableDefinitionWithApp(app_name, component_name): Observable<any> {
    return this.http.get(endpoint + 'updateVarDef?app_name='+app_name+'&component_name='+component_name).pipe(
        map(this.extractData));
    }
  getDashboardTileDeatils(): Observable<any> {
    return this.http.get(endpoint + 'dashboard').pipe(
      map(this.extractData));
  }
  getDBChartDetails(): Observable<any> {
    return this.http.get(endpoint + 'chartsAPI').pipe(
      map(this.extractData));
  }
  getRulesByChartDetails(): Observable<any> {
    return this.http.get(endpoint + 'rulesChartAPI').pipe(
      map(this.extractData));
  }
  getCyclomaticChartDetails(): Observable<any> {
    return this.http.get(endpoint + 'cyclomaticComplexity').pipe(
      map(this.extractData));
  }
  getBusinessConnectedRulesChartDetails(): Observable<any> {
    return this.http.get(endpoint + 'businessConnectedRules').pipe(
      map(this.extractData));
  }
  getInboundOutBoundChartDetails(): Observable<any> {
    return this.http.get(endpoint + 'inboundOutbound').pipe(
      map(this.extractData));
  }
  // program flow component name dropdown value
  getComponentList(): Observable<any> {
    return this.http.get(endpoint + 'procedureFlowList').pipe(
      map(this.extractData));
  }
  getApplicationList(): Observable<any> {
    return this.http.get(endpoint + 'procedureAppList').pipe(
      map(this.extractData));
  }
  getAppList(): Observable<any> {
    return this.http.get(endpoint + 'applicationList').pipe(
      map(this.extractData));
  }
  getdropAppList():Observable<any> {
    return this.http.get(endpoint + 'dropAppList').pipe(
      map(this.extractData));
  }
  getMissingAppList(): Observable<any> {
    return this.http.get(endpoint + 'MissingAppList').pipe(
      map(this.extractData));
  }
  getRuleCategoryList(): Observable<any> {
    return this.http.get(endpoint + 'ruleCategoryList').pipe(
      map(this.extractData));
  }
  getProgramNameList(application_name: string): Observable<any> {
    return this.http.get(endpoint + 'procedureFlowCompList?option=' + application_name).pipe(
      map(this.extractData));
  }
  getProgramNames(type: string, list: string): Observable<any> {
    return this.http.get(endpoint + 'package_list?option=' + type + '&option1=' + list).pipe(
      map(this.extractData));
  }
  getProgramNamesWithApp(type: string, list: string, application_name: string): Observable<any> {
    return this.http.get(endpoint + 'package_list?option=' + type + '&option1=' + list +
                           '&application_name=' + application_name).pipe(
      map(this.extractData));
  }
  getList(type: string): Observable<any> {
    return this.http.get(endpoint + 'package?option=' + type).pipe(
      map(this.extractData));
  }
  getListWithApp(type: string, appname: string): Observable<any> {
    return this.http.get(endpoint + 'package?option=' + type + '&application_name=' + appname).pipe(
      map(this.extractData));
  }
  getMapList(application_name: string): Observable<any> {
    return this.http.get(endpoint + 'procedureFlowMapList?option=' + application_name).pipe(
      map(this.extractData));
  }
   // spider chart get component name based on component type
   getComponentName(component_type: string): Observable<any> {
    return this.http.get(endpoint + 'spiderList?option=' + component_type).pipe(
     // return this.http.get(endpoint + 'spiderList?option=COBOL').pipe(
      map(this.extractData));
  }
  getComponentNameWithApp(component_type: string, application_name): Observable<any> {
    return this.http.get(endpoint + 'spiderList?option=' + component_type +
                          '&application_name=' + application_name).pipe(
     // return this.http.get(endpoint + 'spiderList?option=COBOL').pipe(
      map(this.extractData));
  }
   // spider chart get component type
   getComponentTypeList(): Observable<any> {
    return this.http.get(endpoint + 'spiderTypes').pipe(
      map(this.extractData));
  }
  getComponentTypeListWithApp(application_name: string): Observable<any> {
    return this.http.get(endpoint + 'spiderTypes?application_name=' + application_name).pipe(
      map(this.extractData));
  }

  getComponentTypeListMaster(): Observable<any> {
    return this.http.get(endpoint + 'masterTypes').pipe(
      map(this.extractData));
  }
   // spider chart display
  getSpiderFlow(component_Name: string, component_Type: string): Observable<any> {
    return this.http.get(endpoint + 'spiderDetails?component_name=' + component_Name + '&component_type=' + component_Type).pipe(
      map(this.extractData));
  }
  getSpiderFilterList(component_Name: string, component_Type: string): Observable<any> {
    return this.http.get(endpoint + 'spiderFilterList?component_name=' + component_Name + '&component_type=' + component_Type).pipe(
      map(this.extractData));
  }
  getSpiderFilterFlow(component_Name: string, component_Type: string, filter: string): Observable<any> {
    return this.http.get(endpoint + 'spiderFilterDetails?component_name=' + component_Name + '&component_type=' + component_Type + '&filter=' + filter).pipe(
      map(this.extractData));
  }

  getNaturalSpiderFlow(component_Name: string, component_Type: string, level: string): Observable<any> {
    return this.http.get(endpoint + 'callchain?component_name=' + component_Name + '&component_type=' + component_Type + '&level=' + level).pipe(
      map(this.extractData));
  }
  getcallchainDetails(component_Name: string, component_Type: string, level: string, disp_level: string, array_val: any): Observable<any> {
    return this.http.get('http://172.18.33.162:5010/api/v1/' + 'callchain?component_name=' + component_Name + 
    '&component_type=' + component_Type + '&level=' + level + '&disp_level=' + disp_level + '&array_val=' +array_val ).pipe(
      map(this.extractData));
  }
  getPLSQLSpiderFlow(component_Name: string, component_Type: string, level: string, filter: string): Observable<any> {
    return this.http.get(endpoint + 'callchainplsql?component_name=' + component_Name +
     '&component_type=' + component_Type + '&level=' + level + '&filter=' + filter).pipe(
      map(this.extractData));
  }
  getCallChainFilter(component_name: string, component_type: string): Observable<any> {
    return this.http.get(endpoint + 'callChainFilter?component_name=' + component_name
      + '&component_type=' + component_type).pipe(
      map(this.extractData));
  }
  getCallChainLevel(component_name: string, component_type: string, level: string): Observable<any> {
    return this.http.get('http://172.18.33.162:5010/api/v1/' + 'callchainLevel?component_name=' + component_name
      + '&component_type=' + component_type + '&level='+ level).pipe(
      map(this.extractData));
  }
  getSankeyDetails(application_name: string, integration: string): Observable<any> {
    return this.http.get(endpoint + 'sankeyDetails?application_name=' + application_name +
      '&integration=' + integration).pipe(map(this.extractData));
  }
  getControlFlow(component_Name: string, component_Type: string): Observable<any> {
    return this.http.get(endpoint + 'controlflow?component_name=' + component_Name + '&component_type=' + component_Type).pipe(
      map(this.extractData));
  }

   // batchflow chart get component name based on component type
   getApplicationName(application_name: string): Observable<any> {
    return this.http.get(endpoint + 'batchflowList?option=' + application_name).pipe(
      map(this.extractData));
  }
   // batchflow chart get component type
   getApplicationComponentTypeList(): Observable<any> {
    return this.http.get(endpoint + 'batchflowTypes').pipe(
      map(this.extractData));
  }
   // batchflow chart display
  getBatchFlow(component_name: string, component_type: string): Observable<any> {
    return this.http.get(endpoint + 'batchflowDetails?component_name=' + component_name + '&component_type=' + component_type).pipe(
      map(this.extractData));
  }

  getProcedureFlow(component: string): Observable<any> {
    return this.http.get(endpoint + 'procedureFlow?option=' + component).pipe(
      map(this.extractData));
  }
  getProcedureFlowExtCalls(component: string, flag: string): Observable<any> {
    return this.http.get(endpoint + 'procedureFlow?option=' + component + '&flag=' + flag).pipe(
      map(this.extractData));
  }
  getProcedureFlowEvent(component: string, event: string): Observable<any> {
    return this.http.get(endpoint + 'procedureFlow?option=' + component + '&event=' + event).pipe(
      map(this.extractData));
  }
  getOverallUploadStatus(): Observable<any> {
    return this.http.get(endpoint + 'analysisStatus').pipe(
      map(this.extractData));
  }
  GetProgressStatus(project_path: string): Observable<any> {
   // tslint:disable-next-line:max-line-length
   // return this.http.post(endpoint + 'startAnalysis',{ "option": component } ,{ headers: new HttpHeaders({'Content-type':'Applicaion/json'})}).pipe(
    return this.http.post(endpoint + 'startAnalysis', { project_path } ).pipe(
      map(this.extractData));
  }
  getComponentCode(component_name: string, component_type: string): Observable<any> {
    return this.http.get(endpoint + 'componentCode?component_name=' + component_name + '&component_type=' + component_type).pipe(
      map(this.extractData));
  }
  getComponentCodeWithScroll(component_name: string, component_type: string, line: string): Observable<any> {
    return this.http.get(endpoint + 'componentCode?component_name=' + component_name +
     '&component_type=' + component_type + '&line='+line).pipe(
      map(this.extractData));
  }
  // getScreenPos(component_name: string, component_type: string): Observable<any> {
  //   return this.http.get('http://172.18.33.162:5000/api/v1/' + 'codeString?map_name=' + component_name + '&component_type=' + component_type).pipe(
  //     map(this.extractData));
  // }
  getScreenPos(component_name: string, component_type: string): Observable<any> {
    return this.http.get(endpoint + 'codeString?map_name=' + component_name + '&component_type=' + component_type).pipe(
      map(this.extractData));
  }
  getExpandedComponentCode(component_name: string, component_type: string): Observable<any> {
    return this.http.get(endpoint + 'expandedcomponentCode?component_name=' + component_name + '&component_type=' + component_type).pipe(
      map(this.extractData));
  }
  getExpandedComponentCodeWithScroll(component_name: string, component_type: string, line: string): Observable<any> {
    return this.http.get(endpoint + 'expandedcomponentCode?component_name=' + component_name +
     '&component_type=' + component_type+ '&line='+line).pipe(
      map(this.extractData));
  }
  impactcomponentcodecode(component_name: string, component_type: string): Observable<any> {
    return this.http.get(endpoint + 'impactcomponentcode?component_name=' + component_name + '&component_type=' + component_type).pipe(
      map(this.extractData));
  }

  commentcomponentcode(component_name: string, component_type: string): Observable<any> {
    return this.http.get(endpoint + 'comment_lines?component_name=' + component_name + '&component_type=' + component_type).pipe(
      map(this.extractData));
  }

  getFlowChartContent(component_name: string, para_name: string): Observable<any> {
    // params- procedureName: string, component_Name: string
    return this.http.post(endpoint + 'procFlowChart?component_name=' + component_name + '&para_name=' + para_name, {} ).pipe(
    map(this.extractData));
  }
  getFlowChartTwoContent(component_name: string, para_name: string): Observable<any> {
    // params- procedureName: string, component_Name: string
    return this.http.post(endpoint + 'procFlowChart_RD?component_name=' + component_name + '&para_name=' + para_name, {} ).pipe(
    map(this.extractData));
  }

  showDataModelReport(): Observable<any> {
    return this.http.get(endpoint + 'datamodel').pipe(
      map(this.extractData));
  }
  sendExcelFileGlossary(file): Observable<any> {
    // params- procedureName: string, component_Name: string
    return this.http.post(endpoint + 'uploadglossary', file ).pipe(
    map(this.extractData));
  }
  // userExists(user_id: string): Observable<any> {
  //   return this.http.post('http://localhost:5001/api/v1/' + 'userExists?user_id=' + user_id , {} ).pipe(
  //     map(this.extractData));
  // }
  // validateUser(user_id: string, user_password: string): Observable<any> {
  //   return this.http.post('http://localhost:5001/api/v1/' + 'validateUser?user_id=' + user_id +
  //     '&user_password=' + user_password, {} ).pipe(
  //     map(this.extractData));
  // }
  // createUser(user_id: string, user_password: string): Observable<any> {
  //   return this.http.post('http://localhost:5001/api/v1/' + 'createUser?user_id=' +
  // user_id + '&user_password=' + user_password, {} ).pipe(
  //     map(this.extractData));
  // }
  // below are yet to be developed services
  // not needed as of now
  // getUserRole(): Observable<any> {
  //     return this.http.post(endpoint5 + 'getUserRole', {} ).pipe(
  //       map(this.extractData));
  //   }
  // yet to implement
  // dwnTemplateDocument(): Observable<any> {
  //     return this.http.post(endpoint5 + 'downloadTemplateDocument', {} ).pipe(
  //       map(this.extractData));
  //   }
  createApplication(json): Observable<any> {
    // params- procedureName: string, component_Name: string
    return this.http.post(endpoint + 'createApplication', json ).pipe(
    map(this.extractData));
  }
  sendExcelFile(file): Observable<any> {
    // params- procedureName: string, component_Name: string
    return this.http.post(endpoint + 'sendExcelFile', file ).pipe(
    map(this.extractData));
  }

  getEventList(programName): Observable<any>{
    return this.http.get(endpoint + 'getEventList?option='+programName).pipe(
      map(this.extractData));
  }

}
