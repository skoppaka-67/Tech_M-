import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import * as inputJson from '../input.json';
@Component({
    selector: 'app-x-ref-application',
    templateUrl: './x-ref-application.component.html',
    styleUrls: ['./x-ref-application.component.scss'],
    animations: [routerTransition()]
})
export class XrefApplicationComponent implements OnInit {
    constructor(
        public dataservice: DataService,
        public excelService: ExcelService,
        config: NgbModalConfig,
        private modalService: NgbModal
    ) {
        config.backdrop = 'static';
        config.keyboard = false;

    }
    title = 'app';
    ipValue = inputJson;
    showLoader = false;
    dataSets: any[] = [];
    excelDataSet: any[] = [];
    dtOptions: DataTables.Settings = {};
    dtElement: DataTableDirective;
    dtTrigger: Subject<any> = new Subject();
    compName: string;
    searchFilter: string;
    filterflag: string;
    codeString: string;
    errormessage: string;
    applicationTypeList: any[] = [];
    selectedApplication='';
    component_type;
    // tslint:disable-next-line:max-line-length
    // cobolKeywords = '{" keywords" : ["  DISPLAY " , "  ACCEPT " , "  INITIALIZE " , "  EXIT "  , " IF " , " ELSE " , " END " , " EVALUATE " , " ADD " , " SUBTRACT " , " MULTIPLY " , " DIVIDE " , " COMPUTE " , " MOVE " , " INSPECT " , " TALLYING " , " REPLACING " , " STRING " , " UNSTRING " , " SET " , " SEARCH " , " SEARCH-ALL " , " OPEN " , " CLOSE " , " READ " , " WRITE " , " REWRITE " , " DELETE " , " START " , " CALL " , " PERFORM " , " THRU " , " UNTIL " , " TIMES " , " VARYING " , " GO TO " , " STOP" , " RUN " , " GOBACK " , " SORT " , " MERGE " , " EXEC " , " SQL " , " SELECT " , " UPDATE " , " INSERT " , " FETCH " , " CICS " , " SEND " , " TEXT " , " FROM " , " MAP " , " MAPSET " , " RETURN " , " TRANSID " , " COMMAREA " , " LENGTH " , " RECEIVE " , " INTO " , " EVALUATE " , " EIBAID " , " WHEN " , " XCTL " , " LOAD " , " PROGRAM " , " RELEASE " , " ASKTURN " , " ABSTIME " , " DATESEP " , " FORMATTIME " , " WRITEQ " , " DELETEQ " , " QUEUE " , " READQ " , " STARTBR " , " READPREV " , " READNEXT " , " RIDFLD " , " KEYLENGTH " , " GTEQ " , " EQUAL " , " GENERIC " , " HANDLE " , " CONDITION " , " ERROR " , " ABEND " , " LABEL " , " CANCEL " , " RESET " , " ABCODE " , " IGNORE " , " NOHANDLE " , " USING " , " ENTRY " , " CONTINUE " , " NEXT " , " SENTENCE " ]}';
    ngOnInit() {
        window.scrollTo(0, 0);
        // this.getAppList();
        // this.getXRefDetails();
      // console.log(this.dataSets);
      this.dtOptions =  {
        pagingType: 'full_numbers' ,
        paging : true,
        search : true,
        order: [],
        autoWidth : false,
        searching :true,
        scrollY : '350',
        scrollX : true
      };
      const tableCont = document.querySelector('#table-cont');
        function scrollHandle (e) {
            const scrollTop = this.scrollTop;
            this.querySelector('thead').style.transform = 'translateY(' + scrollTop + 'px)';
        }
        tableCont.addEventListener('scroll', scrollHandle);
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
        // this.dataservice.getApplicationList().subscribe(res => { //microfocus
            this.dataservice.getAppList().subscribe(res => { //tw
          this.applicationTypeList = res.application_list;
          console.clear();
      });
    }
    applicationTypeOnchange(event: any){
        this.selectedApplication = event.target.value;
        inputJson[0].appName = event.target.value;
    }
    onSubmit(){
    // RSapp
    this.showLoader = true;
    if(this.selectedApplication.indexOf('&')!=-1){
      this.selectedApplication = this.selectedApplication.replace('&','$');
    }
    this.dataservice.getXRefApplicationDetails(this.selectedApplication,'', 'no').subscribe(res => {
        this.dataSets = res;
        (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total no of records: ' + res.displayed_count;
        var dataJSON = {};	
          var dataList = [];
          var header = res.headers;
          for(var i=0;i<res.data.length;i++){
            header.forEach(function(header){
              dataJSON[header] = res.data[i][header]
            });
            dataList.push(dataJSON);
            dataJSON = {};
          } 
              //console.log(dataList);
  
          this.excelDataSet = dataList;
        // this.excelDataSet = res.data;
    //    this.dtTrigger.next();
        (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
        (document.getElementById('clearButton') as HTMLInputElement).disabled = false;
        this.showLoader = false;
        const headers = res.headers;
        setTimeout(() => {
            const cname = headers.indexOf('component_name') + 1;
            const clname = headers.indexOf('called_name') + 1;
            $('#xrefDataTbl td:nth-child(' + cname + ')').each(function(i) {
                $(this).addClass('highlight');
            });
            $('#xrefDataTbl td:nth-child(' + clname + ')').each(function(i) {
                $(this).addClass('highlight');
            });
        }, 1100);   

    });
    }
    getXRefDetails() {
        (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
        (document.getElementById('clearButton') as HTMLInputElement).disabled = true;
        this.showLoader = true;
        this.dataservice.getXRefDetails('', 'no').subscribe(res => {
            this.dataSets = res;
            (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total no of records: ' + res.displayed_count;
            var dataJSON = {};	
            var dataList = [];
            var header = res.headers;
            for(var i=0;i<res.data.length;i++){
              header.forEach(function(header){
                dataJSON[header] = res.data[i][header]
              });
              dataList.push(dataJSON);
              dataJSON = {};
            } 
              //console.log(dataList);
  
          this.excelDataSet = dataList;
            // this.excelDataSet = res.data;
            (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
            (document.getElementById('clearButton') as HTMLInputElement).disabled = false;
            this.showLoader = false;
            const headers = res.headers;
            setTimeout(() => {
                const cname = headers.indexOf('component_name') + 1;
                const clname = headers.indexOf('called_name') + 1;
                $('#xrefDataTbl td:nth-child(' + cname + ')').each(function(i) {
                    $(this).addClass('highlight');
                });
                $('#xrefDataTbl td:nth-child(' + clname + ')').each(function(i) {
                    $(this).addClass('highlight');
                });
            }, 1100);   

        });
    }

    open(content, compName, header, compTypeObj) {
        if (header === 'COMPONENT_NAME' || header === 'component_name') {
        //  alert(flowName.name);
          this.modalService.open(content, compName);
          this.compName = compName;
          (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
          (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
          (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
          (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;
        //   (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
        //   (document.getElementById('contentBody') as HTMLInputElement).innerText =
        //     'Component Name: ' + this.compName + '\n' +
        //     'Component Type: ' + compTypeObj['component_type'] + '\n' +
        //     'Code will be displayed below.';
        this.component_type = compTypeObj['component_type'];
            this.dataservice.getComponentCode(this.compName, compTypeObj['component_type']).subscribe(res => {
                this.codeString = res.codeString;
                // this.codeString = this.codeString
                // .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
                // .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
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
                // const cblKeyword = JSON.parse(this.cobolKeywords);
                // // tslint:disable-next-line:forin
                // for (const key in cblKeyword.keywords) {
                // const replaceString = cblKeyword.keywords[key].toString().toLowerCase();
                //     this.codeString = this.codeString
                //     .replace(new RegExp(cblKeyword.keywords[key], 'gi'), '<span style="color: blue;">' + replaceString + '</span>');
                // }
                // console.log((document.getElementById('canvasCode') as HTMLInputElement));
                (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.codeString;
                (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
            }, error => {
                this.errormessage = 'Code not available for current component';
                (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
        });
        }
        if (header === 'called_name' || header === 'CALLED_NAME') {
            this.modalService.open(content, compName);
          this.compName = compName;
          (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
          (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
          (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
          (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;
          this.component_type = compTypeObj['called_type'];
            this.dataservice.getComponentCode(this.compName, compTypeObj['called_type']).subscribe(res => {
                if(Object.keys(res).length != 0){
                    this.codeString = res.codeString;
                    (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
                    // this.codeString = this.codeString
                    // .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
                    // .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
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
                    (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.codeString;
                    (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
                }else{
                    this.errormessage = 'Code not available for current component';
                (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
                }
            }, error => {
                this.errormessage = 'Code not available for current component';
                (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
        });
        }
    }
    exportAsXLSX(): void {
      if(this.selectedApplication.indexOf('&')!=-1){
        this.selectedApplication = this.selectedApplication.replace('&','$');
      }
        this.dataservice.getXRefApplicationDetails(this.selectedApplication, '', 'yes').subscribe(res => {
			var dataJSON = {};	
                var dataList = [];
                var headers = res.headers;
                for(var i=0;i<res.data.length;i++){
                  headers.forEach(function(header){
                    dataJSON[header] = res.data[i][header]
                  });
                  dataList.push(dataJSON);
                  dataJSON = {};
                } 
            this.excelService.exportAsExcelFile(dataList, 'X-Ref Report');
        });
       }

    filterTable() {
        this.searchFilter = (document.getElementById('searchFilter') as HTMLInputElement).value;
        if (this.searchFilter.length > 2) {
            (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
            (document.getElementById('clearButton') as HTMLInputElement).disabled = true;
            this.showLoader = true;
            if(this.selectedApplication.indexOf('&')!=-1){
              this.selectedApplication = this.selectedApplication.replace('&','$');
            }
            this.dataservice.getXRefApplicationDetails(this.selectedApplication,this.searchFilter, 'no').subscribe(res => {
                this.dataSets = res;
                (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total no of records: ' + res.displayed_count;
                var dataJSON = {};	
                var dataList = [];
                var headers = res.headers;
                for(var i=0;i<res.data.length;i++){
                  headers.forEach(function(header){
                    dataJSON[header] = res.data[i][header]
                  });
                  dataList.push(dataJSON);
                  dataJSON = {};
                } 
                    //console.log(dataList);
  
              this.excelDataSet = dataList;
                // this.excelDataSet = res.data;
                setTimeout(() => {
                    $('#xrefDataTbl td:first-child').each(function(i) {
                        $(this).addClass('highlight');
                    });
                    $('#xrefDataTbl td:nth-child(4)').each(function(i) {
                        $(this).addClass('highlight');
                    });
                }, 1100);
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
        if(this.selectedApplication.indexOf('&')!=-1){
          this.selectedApplication = this.selectedApplication.replace('&','$');
        }
        this.dataservice.getXRefApplicationDetails(this.selectedApplication,'', 'no').subscribe(res => {
            this.dataSets = res;
            (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total no of records: ' + res.displayed_count;
            var dataJSON = {};	
          var dataList = [];
          var headersList = res.headers;
          for(var i=0;i<res.data.length;i++){
            headersList.forEach(function(header){
              dataJSON[header] = res.data[i][header]
            });
            dataList.push(dataJSON);
            dataJSON = {};
          } 
              //console.log(dataList);
  
          this.excelDataSet = dataList;
            // this.excelDataSet = res.data;
            (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
            (document.getElementById('clearButton') as HTMLInputElement).disabled = false;
            this.showLoader = false;
            const headers = res.headers;
            setTimeout(() => {
                const cname = headers.indexOf('component_name') + 1;
                const clname = headers.indexOf('called_name') + 1;
                $('#xrefDataTbl td:nth-child(' + cname + ')').each(function(i) {
                    $(this).addClass('highlight');
                });
                $('#xrefDataTbl td:nth-child(' + clname + ')').each(function(i) {
                    $(this).addClass('highlight');
                });
            }, 1100);   
        });
        return false;
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
