import { Component, OnInit, ViewChild } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';


@Component({
    selector: 'app-bre-xref',
    templateUrl: './bre-x-ref.component.html',
    styleUrls: ['./bre-x-ref.component.scss'],
    animations: [routerTransition()]
})

export class BreXRefComponent implements OnInit {

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
    searchFilter = '';
    // tslint:disable-next-line:max-line-length
    // cobolKeywords = '{" keywords" : ["  DISPLAY " , "  ACCEPT " , "  INITIALIZE " , "  EXIT "  , " IF " , " ELSE " , " END " , " EVALUATE " , " ADD " , " SUBTRACT " , " MULTIPLY " , " DIVIDE " , " COMPUTE " , " MOVE " , " INSPECT " , " TALLYING " , " REPLACING " , " STRING " , " UNSTRING " , " SET " , " SEARCH " , " SEARCH-ALL " , " OPEN " , " CLOSE " , " READ " , " WRITE " , " REWRITE " , " DELETE " , " START " , " CALL " , " PERFORM " , " THRU " , " UNTIL " , " TIMES " , " VARYING " , " GO TO " , " STOP" , " RUN " , " GOBACK " , " SORT " , " MERGE " , " EXEC " , " SQL " , " SELECT " , " UPDATE " , " INSERT " , " FETCH " , " CICS " , " SEND " , " TEXT " , " FROM " , " MAP " , " MAPSET " , " RETURN " , " TRANSID " , " COMMAREA " , " LENGTH " , " RECEIVE " , " INTO " , " EVALUATE " , " EIBAID " , " WHEN " , " XCTL " , " LOAD " , " PROGRAM " , " RELEASE " , " ASKTURN " , " ABSTIME " , " DATESEP " , " FORMATTIME " , " WRITEQ " , " DELETEQ " , " QUEUE " , " READQ " , " STARTBR " , " READPREV " , " READNEXT " , " RIDFLD " , " KEYLENGTH " , " GTEQ " , " EQUAL " , " GENERIC " , " HANDLE " , " CONDITION " , " ERROR " , " ABEND " , " LABEL " , " CANCEL " , " RESET " , " ABCODE " , " IGNORE " , " NOHANDLE " , " USING " , " ENTRY " , " CONTINUE " , " NEXT " , " SENTENCE " ]}';

    ngOnInit(): void {
      window.scrollTo(0, 0);
      const tableCont = document.querySelector('#table-cont');
        function scrollHandle (e) {
            const scrollTop = this.scrollTop;
            this.querySelector('thead').style.transform = 'translateY(' + scrollTop + 'px)';
        }
        tableCont.addEventListener('scroll', scrollHandle);
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
      this.applicationList();
     this.getBREDetailsNew('', true, '');
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
      this.getProgramNameList(event.target.value);
      this.selectedApplication = event.target.value;
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
        (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
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
      this.getBREDetailsNew(this.selectedComponent, false, '');
      this.showLoader = false;
    }
    getBREDetailsNew(selectedComponent, intializeTable: boolean, searchFilter) {
      if (intializeTable) {
      this.dataservice.getBREDetailsXref(selectedComponent, '').subscribe(res => {

        // this.element = document.getElementById('divbrecontent') as HTMLElement;
        // this.element.style.visibility = 'visible';
        // // console.log(res.data[4]['rule']).toString().replace(/<br>/g, '\n'));
        for (let i = 0; i < res.data.length; i++) {
          // console.log(res.data[i]['rule']);
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/<br>/g, '\n');
        }
          this.dataSets = res;
          (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total no of records: ' + res.data.length;
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
         // this.dtTrigger.next();
      });
    } else {
      this.dataservice.getBREDetailsXref(selectedComponent, '').subscribe(res => {

        // this.element = document.getElementById('divbrecontent') as HTMLElement;
        // this.element.style.visibility = 'visible';
        // console.log(res.data[4]['rule']).toString().replace(/<br>/g, '\n'));
        for (let i = 0; i < res.data.length; i++) {
          // console.log(res.data[i]['rule']);
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/<br>/g, '\n');
        }

          this.dataSets = res;
          (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total no of records: ' + res.data.length;
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
        // this.rerender();
      });
    }
    }
    // rerender(): void {
    //   this.dtElement.dtInstance.then((dtInstance: DataTables.Api) => {
    //     dtInstance.destroy();
    //     this.dtTrigger.next();
    //  //   this.showLoader = false;
    //   });
    // }
    filterTable() {
      this.searchFilter = (document.getElementById('searchFilter') as HTMLInputElement).value;
      if (this.searchFilter.length > 2) {
          (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
          (document.getElementById('clearButton') as HTMLInputElement).disabled = true;
          this.showLoader = true;
          this.dataservice.getBREDetailsXref(this.selectedComponent, this.searchFilter).subscribe(res => {
              this.dataSets = res;
              (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total no of records: ' + res.data.length;
              this.excelDataSet = res.data;
              (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
              (document.getElementById('clearButton') as HTMLInputElement).disabled = false;
              this.showLoader = false;
          });
      } else {
          alert('Enter atleast 3 characters');
          (document.getElementById('searchFilter') as HTMLInputElement).focus();
          return false;
      }
  }
  clearFilter() {
      (document.getElementById('searchFilter') as HTMLInputElement).value = '';
      this.getBREDetailsNew(this.selectedComponent, false, '');
      return false;
  }
    exportAsXLSX(): void {
    this.excelService.exportAsExcelFile(this.excelDataSet, (document.getElementById('pgmName') as HTMLInputElement).value);
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



