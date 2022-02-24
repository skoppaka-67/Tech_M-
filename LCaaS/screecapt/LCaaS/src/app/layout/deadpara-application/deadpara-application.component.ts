import { Component, OnInit, ViewChild } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { Subject } from 'rxjs';
import { DataTableDirective } from 'angular-datatables';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import * as inputJson from '../input.json';

@Component({
    selector: 'app-deadparaapp',
    templateUrl: './deadpara-application.component.html',
    styleUrls: ['./deadpara-application.component.scss'],
    animations: [routerTransition()]
})
export class DeadparaAppComponent implements OnInit {
  constructor(
    public dataservice: DataService,
    public excelService: ExcelService,
    config: NgbModalConfig,
    private modalService: NgbModal
) {
    config.backdrop = 'static';
    config.keyboard = false;

}
compName: string;
title = 'app';
showLoader = false;
dataSets: any[] = [];
excelDataSet: any[] = [];
dtOptions: DataTables.Settings = {};
@ViewChild(DataTableDirective)
dtElement: DataTableDirective;
dtTrigger: Subject<any> = new Subject();
codeString = '';
errormessage = '';
component_type: string;
applicationTypeList: any[] = [];
selectedApplication='';
// tslint:disable-next-line:max-line-length
// cobolKeywords = '{" keywords" : ["  DISPLAY " , "  ACCEPT " , "  INITIALIZE " , "  EXIT "  , " IF " , " ELSE " , " END " , " EVALUATE " , " ADD " , " SUBTRACT " , " MULTIPLY " , " DIVIDE " , " COMPUTE " , " MOVE " , " INSPECT " , " TALLYING " , " REPLACING " , " STRING " , " UNSTRING " , " SET " , " SEARCH " , " SEARCH-ALL " , " OPEN " , " CLOSE " , " READ " , " WRITE " , " REWRITE " , " DELETE " , " START " , " CALL " , " PERFORM " , " THRU " , " UNTIL " , " TIMES " , " VARYING " , " GO TO " , " STOP" , " RUN " , " GOBACK " , " SORT " , " MERGE " , " EXEC " , " SQL " , " SELECT " , " UPDATE " , " INSERT " , " FETCH " , " CICS " , " SEND " , " TEXT " , " FROM " , " MAP " , " MAPSET " , " RETURN " , " TRANSID " , " COMMAREA " , " LENGTH " , " RECEIVE " , " INTO " , " EVALUATE " , " EIBAID " , " WHEN " , " XCTL " , " LOAD " , " PROGRAM " , " RELEASE " , " ASKTURN " , " ABSTIME " , " DATESEP " , " FORMATTIME " , " WRITEQ " , " DELETEQ " , " QUEUE " , " READQ " , " STARTBR " , " READPREV " , " READNEXT " , " RIDFLD " , " KEYLENGTH " , " GTEQ " , " EQUAL " , " GENERIC " , " HANDLE " , " CONDITION " , " ERROR " , " ABEND " , " LABEL " , " CANCEL " , " RESET " , " ABCODE " , " IGNORE " , " NOHANDLE " , " USING " , " ENTRY " , " CONTINUE " , " NEXT " , " SENTENCE " ]}';
ngOnInit() {
  window.scrollTo(0, 0);
  // this.getAppList();
  this.dtOptions =  {
    pagingType: 'full_numbers' ,
    paging : true,
    deferRender : false,
    // search : true,
 //   ordering : true,
  //  order: [ 0, 'asc'],
  autoWidth : false,
            columnDefs: [
                { 'width': '10%', 'targets': 0 },
                { 'width': '10%', 'targets': 1 },
                { 'width': '20%', 'targets': 2 },
                { 'width': '40%', 'targets': 3 },
                { 'width': '10%', 'targets': 4 },
                { 'width': '10%', 'targets': 5 }
              ],
   // searching :true,
    scrollY : '350',
    scrollX : true
  };
  this.getDeadparaDetails('', true);
  this.getLoadedValues();
}
getLoadedValues() {
  // console.log(inputJson[0], inputJson[0].appName);
  if ( inputJson[0].appName !== undefined && inputJson[0].appName !== '') {
    this.getAppList();
    setTimeout(() => {
      var flag = false;
     var selectedTrends = document.getElementById('appln') as HTMLSelectElement;
     for(var i=0; i < selectedTrends.length; i++)
     {
       if(selectedTrends.options[i].value == inputJson[0].appName ){
          flag=true;
          break;
        }
     }
     if (flag){
      (document.getElementById('appln') as HTMLInputElement).value = inputJson[0].appName;
      this.selectedApplication = inputJson[0].appName;
      document.getElementById('submitBtn').click();
     }
     else {
      var mySelect = document.getElementById('appln') as HTMLSelectElement;
      mySelect.selectedIndex = 1;
      this.selectedApplication = (document.getElementById('appln') as HTMLInputElement).value;
      document.getElementById('submitBtn').click();
    }
      // (document.getElementById('appln') as HTMLInputElement).value = inputJson[0].appName;
      // this.selectedApplication = inputJson[0].appName;
      // document.getElementById('submitBtn').click();
    }, 500);
  } else {
    this.getAppList();
  }
}
getAppList(){
  this.dataservice.getAppList().subscribe(res => {
    this.applicationTypeList = res.application_list;
    console.clear();
});
}
applicationTypeOnchange(event: any){
  this.selectedApplication = event.target.value;
  inputJson[0].appName = event.target.value;
}
onSubmit(){
  if(this.selectedApplication.indexOf('&')!=-1){
    this.selectedApplication = this.selectedApplication.replace('&','$');
  }
  this.getDeadparaDetails(this.selectedApplication, false);
}
getDeadparaDetails(selectedApplication, initalizeTbl: boolean) {
  if(initalizeTbl){
    this.showLoader = true;
    this.dataservice.getDeadparaDetailsWithApp('').subscribe(res => {
        this.dataSets = res;
       // console.log("ss" + res.data[0].dead_para_list);
        for(var i=0; i<res.data.length; i++){
          res.data[i].dead_para_list = JSON.stringify(res.data[i].dead_para_list).replace('[', '').replace(']', '').replace(/"/g, '').trim();
        }
        var dataJSON = {};
            var dataList = [];
            var headerList = res.headers;
            for(var i=0;i<res.data.length;i++){
                for(var j=0;j<headerList.length;j++){
                    dataJSON[headerList[j]] = res.data[i][headerList[j]];
                }
                dataList.push(dataJSON);
                dataJSON= {};
            }
            // console.log(dataList);
          this.excelDataSet = dataList;
       // console.log(res.data);
        this.dtTrigger.next();
        this.showLoader = false;
        setTimeout(() => {
          $( $('#deadpara').DataTable().column(0).nodes()).addClass('highlight');
      }, 1100);
      }, error => {
        console.log(error);
      });
  } else {
    this.showLoader = true;
    if(this.selectedApplication.indexOf('&')!=-1){
      this.selectedApplication = this.selectedApplication.replace('&','$');
    }
    this.dataservice.getDeadparaDetailsWithApp(this.selectedApplication).subscribe(res => {
        this.dataSets = res;
       // console.log("ss" + res.data[0].dead_para_list);
        for(var i=0; i<res.data.length; i++){
          res.data[i].dead_para_list = JSON.stringify(res.data[i].dead_para_list).replace('[', '').replace(']', '').replace(/"/g, '').trim();
        }
        var dataJSON = {};
            var dataList = [];
            var headerList = res.headers;
            for(var i=0;i<res.data.length;i++){
                for(var j=0;j<headerList.length;j++){
                    dataJSON[headerList[j]] = res.data[i][headerList[j]];
                }
                dataList.push(dataJSON);
                dataJSON= {};
            }
            // console.log(dataList);
          this.excelDataSet = dataList;
       // console.log(res.data);
        this.rerender();
        this.showLoader = false;
        setTimeout(() => {
          $( $('#deadpara').DataTable().column(0).nodes()).addClass('highlight');
      }, 1100);
      }, error => {
        console.log(error);
      });
  }
}
rerender(): void {
  this.dtElement.dtInstance.then((dtInstance: DataTables.Api) => {
    dtInstance.destroy();
    this.dtTrigger.next();
  });
}
exportAsXLSX(): void {

 // setTimeout(()=>{
    this.excelService.exportAsExcelFile(this.excelDataSet, 'Dead Para Report');
// }, 5000);
 // this.excelService.exportAsExcelFile(this.dataSets, 'sample');

}
open(content, compName, header, compTypeObj) {
  if (header === 'COMPONENT_NAME' || header === 'component_name') {
  //  alert(flowName.name);
    this.modalService.open(content, compName);
    (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
    (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
    (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true; 
    this.compName = compName;
    (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
    // (document.getElementById('contentBody') as HTMLInputElement).innerText =
    //   'Component Name: ' + this.compName + '\n' +
    //   'Component Type: ' + compTypeObj['component_type'] + '\n' +
    //   'Code will be displayed here.';
    this.component_type = compTypeObj['component_type'];
    this.dataservice.getComponentCode(this.compName, compTypeObj['component_type']).subscribe(res => {
      this.codeString = res.codeString;
     /* this.codeString = this.codeString
      .replace(/\"/g, '"')
      .replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
      .replace(/  /g, '&nbsp;&nbsp;')
      .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');*/
      try{
        this.codeString = this.codeString.replace(/\"/g, '"')
      } catch{
        console.log('err 1');
      }
      try{
        this.codeString = this.codeString
        .replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 2');
      }
      try{
        this.codeString = this.codeString
      .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 3');
      }
      try{
        this.codeString = this.codeString
      .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 4');
      }
      try{
        this.codeString = this.codeString
      .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 5');
      }
      try{
        this.codeString = this.codeString
      .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 6');
      }
      try{
        this.codeString = this.codeString
      .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 7');
      }
      try{
        this.codeString = this.codeString
      .replace(/  /g, '&nbsp;&nbsp;')
      } catch {
        console.log('err 8');
      }
      try{
        this.codeString = this.codeString
      .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 9');
      }
      // const cblKeyword = JSON.parse(this.cobolKeywords);
      //       // tslint:disable-next-line:forin
      //   for (const key in cblKeyword.keywords) {
      //   const replaceString = cblKeyword.keywords[key].toString().toLowerCase();
      //       this.codeString = this.codeString
      //       .replace(new RegExp(cblKeyword.keywords[key], 'gi'), '<span style="color: blue;">' + replaceString + '</span>');
      //   }
        document.getElementById('canvasCode').innerHTML = this.codeString;
        (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
    }, error => {
      this.errormessage = 'Code not available for current component';
      (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
});
  }
}
showExpandedCode(){
  (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
  (document.getElementById('canvasCode') as HTMLInputElement).style.height = '0%';
  (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'visible';
  (document.getElementById('expandedCode') as HTMLInputElement).style.height = '100%';

  (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = true;
  (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = false;

  this.dataservice.getExpandedComponentCode(this.compName, this.component_type).subscribe(res => {
    this.codeString = res.codeString;
    /*this.codeString = this.codeString
    .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
    .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
    .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
    .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
    .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
    .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
    .replace(/  /g, '&nbsp;&nbsp;')
    .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');*/
    try{
      this.codeString = this.codeString.replace(/\"/g, '"')
    } catch{
      console.log('err 1');
    }
    try{
      this.codeString = this.codeString
      .replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
    } catch {
      console.log('err 2');
    }
    try{
      this.codeString = this.codeString
    .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
    } catch {
      console.log('err 3');
    }
    try{
      this.codeString = this.codeString
    .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
    } catch {
      console.log('err 4');
    }
    try{
      this.codeString = this.codeString
    .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
    } catch {
      console.log('err 5');
    }
    try{
      this.codeString = this.codeString
    .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
    } catch {
      console.log('err 6');
    }
    try{
      this.codeString = this.codeString
    .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
    } catch {
      console.log('err 7');
    }
    try{
      this.codeString = this.codeString
    .replace(/  /g, '&nbsp;&nbsp;')
    } catch {
      console.log('err 8');
    }
    try{
      this.codeString = this.codeString
    .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;')
    } catch {
      console.log('err 9');
    }
      document.getElementById('expandedCode').innerHTML = this.codeString;
      (document.getElementById('expandedCode') as HTMLInputElement).style.fontFamily = 'Courier';
  }, error => {
    this.errormessage = 'Code not available for current component';
    (document.getElementById('expandedCode') as HTMLInputElement).innerHTML = this.errormessage;
});
}
showCode(){
  (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
  (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
  (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'visible';
  (document.getElementById('canvasCode') as HTMLInputElement).style.height = '100%';
  (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
  (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;

}

}
