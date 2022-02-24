import { Component, OnInit, ViewChild } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';

import * as inputJson from '../input.json';

@Component({
    selector: 'app-bre',
    templateUrl: './bre.component.html',
    styleUrls: ['./bre.component.scss'],
    animations: [routerTransition()]
})

export class BreComponent implements OnInit {

  constructor(
    public dataservice: DataService,
    public excelService: ExcelService,
    config: NgbModalConfig,
    private modalService: NgbModal
) {
    config.backdrop = 'static';
    config.keyboard = false;

}
  title = 'BRE Report';
  componentList: any[] = [];
   selectedComponent = '';
   dataSets: any = null;
    excelDataSet: any[] = [];
    dtOptions: DataTables.Settings = {};
    @ViewChild(DataTableDirective)
    dtElement: DataTableDirective;
    element: HTMLElement;
    dtTrigger: Subject<any> = new Subject();
    showLoader = false;
    compName = '';
    codeString = '';
    errormessage = '';
    applicationTypeList: any[] = [];
    programNameList: any[] = [];
    selectedApplication = '';
    // tslint:disable-next-line:max-line-length
    // cobolKeywords = '{" keywords" : ["  DISPLAY " , "  ACCEPT " , "  INITIALIZE " , "  EXIT "  , " IF " , " ELSE " , " END " , " EVALUATE " , " ADD " , " SUBTRACT " , " MULTIPLY " , " DIVIDE " , " COMPUTE " , " MOVE " , " INSPECT " , " TALLYING " , " REPLACING " , " STRING " , " UNSTRING " , " SET " , " SEARCH " , " SEARCH-ALL " , " OPEN " , " CLOSE " , " READ " , " WRITE " , " REWRITE " , " DELETE " , " START " , " CALL " , " PERFORM " , " THRU " , " UNTIL " , " TIMES " , " VARYING " , " GO TO " , " STOP" , " RUN " , " GOBACK " , " SORT " , " MERGE " , " EXEC " , " SQL " , " SELECT " , " UPDATE " , " INSERT " , " FETCH " , " CICS " , " SEND " , " TEXT " , " FROM " , " MAP " , " MAPSET " , " RETURN " , " TRANSID " , " COMMAREA " , " LENGTH " , " RECEIVE " , " INTO " , " EVALUATE " , " EIBAID " , " WHEN " , " XCTL " , " LOAD " , " PROGRAM " , " RELEASE " , " ASKTURN " , " ABSTIME " , " DATESEP " , " FORMATTIME " , " WRITEQ " , " DELETEQ " , " QUEUE " , " READQ " , " STARTBR " , " READPREV " , " READNEXT " , " RIDFLD " , " KEYLENGTH " , " GTEQ " , " EQUAL " , " GENERIC " , " HANDLE " , " CONDITION " , " ERROR " , " ABEND " , " LABEL " , " CANCEL " , " RESET " , " ABCODE " , " IGNORE " , " NOHANDLE " , " USING " , " ENTRY " , " CONTINUE " , " NEXT " , " SENTENCE " ]}';

    ngOnInit(): void {
      window.scrollTo(0, 0);
      this.dtOptions =  {
        pagingType: 'full_numbers' ,
        paging : true,
        search : true,
     //   ordering : true,
        order: [],
        autoWidth : false,
            columnDefs: [
                { 'width': '10%', 'targets': 0 },
                { 'width': '20%', 'targets': 1 },
                { 'width': '40%', 'targets': 2 },
                { 'width': '10%', 'targets': 3 },
                { 'width': '20%', 'targets': 4 }
              ],
       // searching :true,
        scrollY : '350',
        scrollX : true
      };
      (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
      // this.getComponentList();
      // this.applicationList();
      this.getLoadedValues();
     this.getBREDetailsNew('', true);
    }
    getLoadedValues() {
      // console.log(inputJson[0], inputJson[0].appName);
      if ( inputJson[0].appName !== undefined && inputJson[0].appName !== '') {
        this.applicationList();
        setTimeout(() => {
          // (document.getElementById('appln') as HTMLInputElement).value = inputJson[0].appName;
          // this.selectedApplication = inputJson[0].appName;
          // this.getProgramNameList(inputJson[0].appName);
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
          // document.getElementById('submitBtn').click();
          this.getProgramNameList(inputJson[0].appName);
        }
        else {
          var mySelect = document.getElementById('appln') as HTMLSelectElement;
          mySelect.selectedIndex = 1;
          this.selectedApplication = (document.getElementById('appln') as HTMLInputElement).value;
          // document.getElementById('submitBtn').click();
          this.getProgramNameList((document.getElementById('appln') as HTMLInputElement).value);
        }
          setTimeout(() => {
            // (document.getElementById('pgmName') as HTMLInputElement).value = inputJson[0].compName + ".cbl";
            // this.selectedComponent = inputJson[0].compName + ".cbl";

            var flag = false;
            var selectedTrends = document.getElementById('pgmName') as HTMLSelectElement;
            for(var i=0; i < selectedTrends.length; i++)
            {
              if(selectedTrends.options[i].value == inputJson[0].compName + ".cbl"){
                  flag=true;
                  break;
                }
            }
            if (flag){
              (document.getElementById('pgmName') as HTMLInputElement).value = inputJson[0].compName + ".cbl"
              this.selectedComponent = inputJson[0].compName + ".cbl";
            }
            else {
              var mySelect = document.getElementById('pgmName') as HTMLSelectElement;
              mySelect.selectedIndex = 1;
              this.selectedComponent = (document.getElementById('pgmName') as HTMLInputElement).value;
            }

              setTimeout(() => {
                  document.getElementById('submitBtn').click();
              }, 500);
          }, 500);
        }, 500);
      } else {
        this.applicationList();
      }
    }
    getComponentList() {
      this.dataservice.getComponentList().subscribe(res => {
          this.componentList = res.program_list;
         // console.log(res);
      });
    }
    applicationList() {
      this.dataservice.getApplicationList().subscribe(res => {
        this.applicationTypeList = res.application_list;
        console.clear();
    });
    }
    applicationTypeOnchange(event: any) {
      this.selectedApplication = event.target.value;
      inputJson[0].appName = event.target.value;
      if(this.selectedApplication.indexOf('&')!=-1){
        this.selectedApplication = this.selectedApplication.replace('&','$');
      }
      this.getProgramNameList(this.selectedApplication);
    }
    getProgramNameList(selectedApplication) {
      this.dataservice.getProgramNameList(selectedApplication).subscribe(res => {
        this.programNameList = res.component_list;
    });
    }
    programNameOnchange(event: any) {
      if (event.target.value === '') {
        this.selectedComponent = '';
        (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
    } else {
        this.selectedComponent = event.target.value;
        inputJson[0].compName = event.target.value.split(".")[0];
        console.log('onchange', event.target.value.split(".")[0], inputJson[0].compName);
        (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
    }
    }

    onChange(component: string) {
      if (component === '') {
          this.selectedComponent = '';
          (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
      } else {
          this.selectedComponent = component;
          inputJson[0].compName = component.split(".")[0];
          console.log('onchange', component.split(".")[0], inputJson[0].compName);
          (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
      }
    }
    onSubmit() {
      this.showLoader = true;
      console.log(this.selectedComponent);
      this.getBREDetailsNew(this.selectedComponent, false);
      this.showLoader = false;
    }
    getBREDetailsNew(selectedComponent, intializeTable: boolean) {
      if (intializeTable) {
      // this.dataservice.getBREDetailsNew(selectedComponent).subscribe(res => { //for other instances
        this.dataservice.getBREDetailsNewFlag(selectedComponent, 'no').subscribe(res=>{ //for crst
        // this.element = document.getElementById('divbrecontent') as HTMLElement;
        // this.element.style.visibility = 'visible';
        // // console.log(res.data[4]['rule']).toString().replace(/<br>/g, '\n'));
        for (let i = 0; i < res.data.length; i++) {
          // console.log(res.data[i]['rule']);
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/<br>/g, '\n');
        }
          this.dataSets = res;
          if(res.msg==undefined)
            (document.getElementById('msg') as HTMLInputElement).innerHTML = '';
          else
            (document.getElementById('msg') as HTMLInputElement).innerHTML = res.msg;
          var dataJSON = {};
            var dataList = [];
            var headers = res.headers;
            for(var i=0;i<res.data.length;i++){
                for(var j=0;j<headers.length;j++){
                    dataJSON[headers[j]] = res.data[i][headers[j]];
                }
                dataList.push(dataJSON);
                dataJSON= {};
            }
            // console.log(dataList);

          this.excelDataSet = dataList;
          this.dtTrigger.next();
      });
    } else {
      // this.dataservice.getBREDetailsNew(selectedComponent).subscribe(res => { //for other instances
        this.dataservice.getBREDetailsNewFlag(selectedComponent, 'no').subscribe(res=>{ //for crst
        // this.element = document.getElementById('divbrecontent') as HTMLElement;
        // this.element.style.visibility = 'visible';
        // console.log(res.data[4]['rule']).toString().replace(/<br>/g, '\n'));
        for (let i = 0; i < res.data.length; i++) {
          // console.log(res.data[i]['rule']);
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/<br>/g, '\n');
        }
          this.dataSets = res;
          if(res.msg==undefined)
            (document.getElementById('msg') as HTMLInputElement).innerHTML = '';
          else
            (document.getElementById('msg') as HTMLInputElement).innerHTML = res.msg;
          var dataJSON = {};
            var dataList = [];
            var headers = res.headers;
            for(var i=0;i<res.data.length;i++){
                for(var j=0;j<headers.length;j++){
                    dataJSON[headers[j]] = res.data[i][headers[j]];
                }
                dataList.push(dataJSON);
                dataJSON= {};
            }
            // console.log(dataList);

          this.excelDataSet = dataList;
         this.rerender();
      });
    }
    }
    rerender(): void {
      this.dtElement.dtInstance.then((dtInstance: DataTables.Api) => {
        dtInstance.destroy();
        this.dtTrigger.next();
     //   this.showLoader = false;
      });
    }
    exportAsXLSX(): void {
      // this.excelService.exportAsExcelFile(this.excelDataSet, (document.getElementById('pgmName') as HTMLInputElement).value);
      this.dataservice.getBREDetailsNewFlag(this.selectedComponent, 'yes').subscribe(res=>{
        for (let i = 0; i < res.data.length; i++) {
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/<br>/g, '\n');
        }
        if(res.msg==undefined)
          (document.getElementById('msg') as HTMLInputElement).innerHTML = '';
        else
          (document.getElementById('msg') as HTMLInputElement).innerHTML = res.msg;
          var dataJSON = {};
            var dataList = [];
            var headers = res.headers;
            for(var i=0;i<res.data.length;i++){
                for(var j=0;j<headers.length;j++){
                    dataJSON[headers[j]] = res.data[i][headers[j]];
                }
                dataList.push(dataJSON);
                dataJSON= {};
            }
            this.excelService.exportAsExcelFile(dataList, (document.getElementById('pgmName') as HTMLInputElement).value);
      });
    }
    open(content) {
        this.modalService.open(content);
        (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
        (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
        (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
        (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;
        this.compName = this.selectedComponent;
        // this.compName = this.compName.split('.')[0];
        (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
        // (document.getElementById('contentBody') as HTMLInputElement).innerText =
        //   'Component Name: ' + this.compName + '\n' +
        //   'Component Type: ' + 'COBOL' + '\n' +
        //   'Code will be displayed here.';
        this.dataservice.getComponentCode(this.compName, 'COBOL').subscribe(res => {
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
          // const cblKeyword = JSON.parse(this.cobolKeywords);
          //   // tslint:disable-next-line:forin
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
  showExpandedCode(){
    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('canvasCode') as HTMLInputElement).style.height = '0%';
    (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'visible';
    (document.getElementById('expandedCode') as HTMLInputElement).style.height = '100%';

    (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = true;
    (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = false;

    this.dataservice.getExpandedComponentCode(this.compName, 'COBOL').subscribe(res => {
      this.codeString = res.codeString;
      // this.codeString = this.codeString
      // .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      // .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      // .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
      // .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
      // .replace(/  /g, '&nbsp;&nbsp;')
      // .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');

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



