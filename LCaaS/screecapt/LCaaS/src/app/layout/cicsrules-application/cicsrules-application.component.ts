import { Component, OnInit, ViewChild } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import * as inputJson from '../input.json';


@Component({
    selector: 'app-cicsrules-app',
    templateUrl: './cicsrules-application.component.html',
    styleUrls: ['./cicsrules-application.component.scss'],
    animations: [routerTransition()]
})

export class CicsRulesAppComponent implements OnInit {

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
                { 'width': '10%', 'targets': 1 },
                { 'width': '10%', 'targets': 2 },
                { 'width': '40%', 'targets': 3 }
              ],
       // searching :true,
        scrollY : '350',
        scrollX : true
      };
      // (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
      // this.getComponentList();
      // this.applicationList();
      this.getLoadedValues();
     this.getCicsRulesDetails('', true);
    }
    getLoadedValues() {
      if ( inputJson[0].appName !== undefined && inputJson[0].appName !== '') {
        this.applicationList();
        setTimeout(() => {
          // (document.getElementById('appln') as HTMLInputElement).value = inputJson[0].appName;
          // this.selectedApplication = inputJson[0].appName;
          // this.getMapList(inputJson[0].appName);
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
          this.getMapList(inputJson[0].appName);
        }
        else {
          var mySelect = document.getElementById('appln') as HTMLSelectElement;
          mySelect.selectedIndex = 1;
          this.selectedApplication = (document.getElementById('appln') as HTMLInputElement).value;
          // document.getElementById('submitBtn').click();
          this.getMapList((document.getElementById('appln') as HTMLInputElement).value);
        }
          setTimeout(() => {
            // (document.getElementById('pgmName') as HTMLInputElement).value = inputJson[0].cicsValidationMapName;
            // this.selectedComponent = inputJson[0].cicsValidationMapName;
            // document.getElementById('submitBtn').click();

            var flag = false;
            var selectedTrends = document.getElementById('pgmName') as HTMLSelectElement;
            for(var i=0; i < selectedTrends.length; i++)
            {
              if(selectedTrends.options[i].value == inputJson[0].cicsValidationMapName){
                  flag=true;
                  break;
                }
            }
            if (flag){
              (document.getElementById('pgmName') as HTMLInputElement).value = inputJson[0].cicsValidationMapName
              this.selectedComponent = inputJson[0].cicsValidationMapName;
              document.getElementById('submitBtn').click();
            }
            else {
              var mySelect = document.getElementById('pgmName') as HTMLSelectElement;
              mySelect.selectedIndex = 1;
              this.selectedComponent = (document.getElementById('pgmName') as HTMLInputElement).value;
              document.getElementById('submitBtn').click();
            }

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
      this.getMapList(event.target.value);
      this.selectedApplication = event.target.value;
      inputJson[0].appName = event.target.value;
    }
    getMapList(selectedApplication) {
      this.dataservice.getMapList(selectedApplication).subscribe(res => {
        this.programNameList = res.component_list;
    });
    }
    programNameOnchange(event: any) {
      if (event.target.value === '') {
        this.selectedComponent = '';
        // (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
    } else {
        this.selectedComponent = event.target.value;
        inputJson[0].cicsValidationMapName = event.target.value;
        // (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
    }
    }

    onChange(component: string) {
      if (component === '') {
          this.selectedComponent = '';
          (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
      } else {
          this.selectedComponent = component;
          console.log('onchange');
          (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
      }
    }
    onSubmit() {
      this.showLoader = true;
      this.getCicsRulesDetails(this.selectedComponent, false);
      this.showLoader = false;
    }
    getCicsRulesDetails(selectedComponent, intializeTable: boolean) {
      if (intializeTable) {
      this.dataservice.getCicsRulesDetails(selectedComponent).subscribe(res => {

        // this.element = document.getElementById('divbrecontent') as HTMLElement;
        // this.element.style.visibility = 'visible';
        // // console.log(res.data[4]['rule']).toString().replace(/<br>/g, '\n'));
        for (let i = 0; i < res.data.length; i++) {
          // console.log(res.data[i]['rule']);
          res.data[i]['validation_rule'] = res.data[i]['validation_rule'].toString().replace(/<br>/g, '\n');
        }
          this.dataSets = res;
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
          this.dtTrigger.next();
          setTimeout(() => {
            $( $('#dataTbl').DataTable().column(0).nodes()).addClass('highlight');
          }, 1100);
      });
    } else {
      this.dataservice.getCicsRulesDetails(selectedComponent).subscribe(res => {

        // this.element = document.getElementById('divbrecontent') as HTMLElement;
        // this.element.style.visibility = 'visible';
        // console.log(res.data[4]['rule']).toString().replace(/<br>/g, '\n'));
        for (let i = 0; i < res.data.length; i++) {
          // console.log(res.data[i]['rule']);
          res.data[i]['validation_rule'] = res.data[i]['validation_rule'].toString().replace(/<br>/g, '\n');
        }
          this.dataSets = res;
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
          this.rerender();
          setTimeout(() => {
            $( $('#dataTbl').DataTable().column(0).nodes()).addClass('highlight');
          }, 1100);
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
    this.excelService.exportAsExcelFile(this.excelDataSet, (document.getElementById('pgmName') as HTMLInputElement).value);
    }
    open(content, compName, header, compTypeObj) {
      if (header === 'PROGRAM_NAME' || header === 'program_name') {
        this.modalService.open(content);
        (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
        (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
        (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
        (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;
        this.compName = compName;
        (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
        this.dataservice.getComponentCode(this.compName, 'COBOL').subscribe(res => {
          this.codeString = res.codeString;
          this.codeString = this.codeString
          .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
          .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
          .replace(/  /g, '&nbsp;&nbsp;')
          .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');
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

    this.dataservice.getExpandedComponentCode(this.compName, 'COBOL').subscribe(res => {
      this.codeString = res.codeString;
      //this.codeString = this.codeString
      /*.replace(/\"/g, '"')
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



