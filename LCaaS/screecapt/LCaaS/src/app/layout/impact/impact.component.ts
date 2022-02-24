import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import * as inputJson from '../input.json';

@Component({
    selector: 'app-impact',
    templateUrl: './impact.component.html',
    styleUrls: ['./impact.component.scss'],
    animations: [routerTransition()]
})
export class ImpactComponent implements OnInit {
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
    showExcel: boolean = false;
    showSummaryView: boolean = false;
    showDetialedView: boolean = false;
    component_type: string;
    compLine: string;
    value;
    dataJson: any[] = [];
    compNameList = [];
    // applicationTypeList: any[] = [];
    // selectedApplication='';
    // tslint:disable-next-line:max-line-length
    // cobolKeywords = '{" keywords" : ["  DISPLAY " , "  ACCEPT " , "  INITIALIZE " , "  EXIT "  , " IF " , " ELSE " , " END " , " EVALUATE " , " ADD " , " SUBTRACT " , " MULTIPLY " , " DIVIDE " , " COMPUTE " , " MOVE " , " INSPECT " , " TALLYING " , " REPLACING " , " STRING " , " UNSTRING " , " SET " , " SEARCH " , " SEARCH-ALL " , " OPEN " , " CLOSE " , " READ " , " WRITE " , " REWRITE " , " DELETE " , " START " , " CALL " , " PERFORM " , " THRU " , " UNTIL " , " TIMES " , " VARYING " , " GO TO " , " STOP" , " RUN " , " GOBACK " , " SORT " , " MERGE " , " EXEC " , " SQL " , " SELECT " , " UPDATE " , " INSERT " , " FETCH " , " CICS " , " SEND " , " TEXT " , " FROM " , " MAP " , " MAPSET " , " RETURN " , " TRANSID " , " COMMAREA " , " LENGTH " , " RECEIVE " , " INTO " , " EVALUATE " , " EIBAID " , " WHEN " , " XCTL " , " LOAD " , " PROGRAM " , " RELEASE " , " ASKTURN " , " ABSTIME " , " DATESEP " , " FORMATTIME " , " WRITEQ " , " DELETEQ " , " QUEUE " , " READQ " , " STARTBR " , " READPREV " , " READNEXT " , " RIDFLD " , " KEYLENGTH " , " GTEQ " , " EQUAL " , " GENERIC " , " HANDLE " , " CONDITION " , " ERROR " , " ABEND " , " LABEL " , " CANCEL " , " RESET " , " ABCODE " , " IGNORE " , " NOHANDLE " , " USING " , " ENTRY " , " CONTINUE " , " NEXT " , " SENTENCE " ]}';
    ngOnInit() {
        window.scrollTo(0, 0);
        (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
        $('#searchFilter').change(function() {
            if ((document.getElementById('searchFilter') as HTMLInputElement).value === '') {
                (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
            } else {
                (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
            }
        });
        this.getLoadedValues();
        // this.applicationList();
        // this.getImpactDetails();
      // console.log(this.dataSets);
    }
    getLoadedValues() {
      // console.log(inputJson[0], inputJson[0].appName);
      if ( inputJson[0].variableSearchFiler !== undefined && inputJson[0].variableSearchFiler !== '') {
        setTimeout(() => {
          (document.getElementById('searchFilter') as HTMLInputElement).value = inputJson[0].variableSearchFiler;
          (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
          document.getElementById('searchButton').click();
        }, 500);
      }
    }
    // applicationList(){
    //     this.dataservice.getApplicationList().subscribe(res => {
    //       this.applicationTypeList = res.application_list;
    //       console.clear();
    //   });
    // }
    // applicationTypeOnchange(event: any){
    //     this.selectedApplication = event.target.value;
    // }
    getImpactDetails() {
        (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
        // (document.getElementById('clearButton') as HTMLInputElement).disabled = true;
        this.showLoader = true;
        this.dataservice.getImpactDetails('', 'no').subscribe(res => {
            // tslint:disable-next-line:no-shadowed-variable
            for (let i = 0; i < res.data.length; i++) {
                // tslint:disable-next-line:max-line-length
                res.data[i]['sourcestatements'] = res.data[i]['sourcestatements'].toString().replace(/<span style="color:green">/g, '').replace(/<\/span>/g, '');
            }
	          // tslint:disable-next-line:no-shadowed-variable
	          for (let i = 0; i < res.data.length; i++) {
          	  // console.log(res.data[i]['rule']);
	            res.data[i]['sourcestatements'] = res.data[i]['sourcestatements'].toString().replace(/<br>/g, '\n');
            }
            this.dataSets = res;
            (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total results found: ' + res.displayed_count;
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
            (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
            // (document.getElementById('clearButton') as HTMLInputElement).disabled = false;
            this.showLoader = false;
            const headers = res.headers;
            setTimeout(() => {
                const cname = headers.indexOf('pgm_name') + 1;
                // const clname = headers.indexOf('called_name') + 1;
                $('#xrefDataTblSummary td:nth-child(' + cname + ')').each(function(i) {
                    $(this).addClass('highlight');
                });
                // $('#xrefDataTbl td:nth-child(' + clname + ')').each(function(i) {
                //     $(this).addClass('highlight');
                // });
            }, 1100);

        });
    }
    openSummary(content, compName, header, compTypeObj){
        if (header === 'COMPONENT_NAME' || header === 'component_name' ||
        header === 'PGM_NAME' || header === 'pgm_name') {
              this.modalService.open(content, compName);
              this.compName = compName;
              (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
                (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
                (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
                (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;
                this.component_type = compTypeObj['component_type'];
                this.compLine = compTypeObj['sourcestatements'];
                this.dataservice.getComponentCodeWithScroll(this.compName, compTypeObj['component_type'],
                 compTypeObj['sourcestatements']).subscribe(res => {
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
                    (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.codeString;
                    (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
                    setTimeout(() => {
                      const elmnt = document.getElementById('canvasScroll');
                      try {
                        elmnt.scrollIntoView();
                      } catch (e) {
                        console.log(e + 'Line not found');
                      }
                    }, 1100);
                }, error => {
                    this.errormessage = 'Code not available for current component';
                    (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
            });
            }
    }
    open(content, compName, header, compTypeObj) {
      console.log('open called', header);
        if (header === 'COMPONENT_NAME' || header === 'component_name') {
          console.log('comp name clicked');
        //  alert(flowName.name);
          this.modalService.open(content, compName);
          (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
          (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
          (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
          (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;
          this.compName = compName;
          console.log(this.compName);
        //   (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
        //   (document.getElementById('contentBody') as HTMLInputElement).innerText =
        //     'Component Name: ' + this.compName + '\n' +
        //     'Component Type: ' + compTypeObj['component_type'] + '\n' +
        //     'Code will be displayed below.';
          this.component_type = compTypeObj['component_type'];
          console.log(this.component_type);
          this.compLine = compTypeObj['sourcestatements'];
          console.log(compTypeObj['sourcestatements'], this.compLine);
        // getComponentCode
            this.dataservice.getComponentCodeWithScroll(this.compName, compTypeObj['component_type'],
             compTypeObj['sourcestatements']).subscribe(res => {
                this.codeString = res.codeString;
               /* this.codeString = this.codeString
                .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
                .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
                .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
                .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
                .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
                .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
                .replace(/  /g, '&nbsp;&nbsp;')
                .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');
                // const cblKeyword = JSON.parse(this.cobolKeywords);*/
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
                // // tslint:disable-next-line:forin
                // for (const key in cblKeyword.keywords) {
                // const replaceString = cblKeyword.keywords[key].toString().toLowerCase();
                //     this.codeString = this.codeString
                //     .replace(new RegExp(cblKeyword.keywords[key], 'gi'), '<span style="color: blue;">' + replaceString + '</span>');
                // }
                // console.log((document.getElementById('canvasCode') as HTMLInputElement));
                (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.codeString;
                (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
                setTimeout(() => {
                  const elmnt = document.getElementById('canvasScroll');
                  try {
                    elmnt.scrollIntoView();
                  } catch (e) {
                    console.log(e + 'Line not found');
                  }
                }, 1100);
            }, error => {
                this.errormessage = 'Code not available for current component';
                (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
        });
        }
        // if (header === 'called_name' || header === 'CALLED_NAME') {
        //     this.modalService.open(content, compName);
        //   this.compName = compName;
        //     this.dataservice.getComponentCode(this.compName, compTypeObj['called_type']).subscribe(res => {
        //         if(Object.keys(res).length != 0){
        //             this.codeString = res.codeString;
        //             (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
        //             this.codeString = this.codeString
        //             .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
        //             .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
        //             .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
        //             .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
        //             .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
        //             .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
        //             .replace(/  /g, '&nbsp;&nbsp;')
        //             .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');
        //             (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.codeString;
        //             (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
        //         }else{
        //             this.errormessage = 'Code not available for current component';
        //         (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
        //         }
        //     }, error => {
        //         this.errormessage = 'Code not available for current component';
        //         (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
        // });
        // }
    }
    exportAsXLSX(): void {
        // this.dataservice.getImpactDetails('', 'yes').subscribe(res => {
        //     this.excelService.exportAsExcelFile(res.data, 'Variable Impact');
        // });
        if (this.showSummaryView) {
            this.dataservice.getImpactDetails(this.searchFilter, 'yes').subscribe(res => {
                for (let i = 0; i < res.data.length; i++) {
                    // tslint:disable-next-line:max-line-length
                    res.data[i]['sourcestatements'] = res.data[i]['sourcestatements'].toString().replace(/<span style="color:green">/g, '').replace(/<span id="canvasScroll">/g, '').replace(/<\/span>/g, '');
                }
		        for (let i = 0; i < res.data.length; i++) {
		          res.data[i]['sourcestatements'] = res.data[i]['sourcestatements'].toString().replace(/<br>/g, '\n');
        	   }
                this.excelService.exportAsExcelFile(res.data, 'Variable Impact Detail');
            });
        }
            
        if(this.showDetialedView) {
            this.dataservice.getImpactSummaryDetails(this.searchFilter, 'yes').subscribe(res => {
            //     for (let i = 0; i < res.data.length; i++) {
            //         res.data[i]['sourcestatements'] = res.data[i]['sourcestatements'].toString().replace(/<span style="color:green">/g, '').replace(/<\/span>/g, '');
            //     }
		    //     for (let i = 0; i < res.data.length; i++) {
		    //       res.data[i]['sourcestatements'] = res.data[i]['sourcestatements'].toString().replace(/<br>/g, '\n');
        	//    }
                this.excelService.exportAsExcelFile(res.data, 'Variable Impact Summary');
            });
        }
        }
    filterTableSummaryView(show) {
        if (show) {
            this.showDetialedView = false;
            this.showSummaryView = true;
        }
        // this.filterTblDetail();
        this.filterTable();
    }
    filterTblDetail(){
        this.searchFilter = (document.getElementById('searchFilter') as HTMLInputElement).value;
            (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
            this.showLoader = true;
            this.dataservice.getImpactSummaryDetails(this.searchFilter, 'no').subscribe(res => {
                this.showExcel = true;
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
                (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total results found: ' + res.displayed_count;
                setTimeout(() => {
                    $('#xrefDataTbl td:first-child').each(function(i) {
                        $(this).addClass('highlight');
                    });
                }, 1100);
                setTimeout(() => {
                    const tableCont = document.querySelector('#table-cont');
                        function scrollHandled (e) {
                            const scrollTop = this.scrollTop;
                            this.querySelector('thead').style.transform = 'translateY(' + scrollTop + 'px)';
                        }
                        tableCont.addEventListener('scroll', scrollHandled);
                }, 1100);
                (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
                this.showLoader = false;
            });
    }
    filterTable() {
        this.searchFilter = (document.getElementById('searchFilter') as HTMLInputElement).value;
        if (this.searchFilter !== '') {
            (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
            this.showLoader = true;
            this.dataservice.getImpactDetails(this.searchFilter, 'no').subscribe(res => {
                this.showExcel = true;
                // tslint:disable-next-line:no-shadowed-variable
                for (let i = 0; i < res.data.length; i++) {
                    // tslint:disable-next-line:max-line-length
                    res.data[i]['sourcestatements'] = res.data[i]['sourcestatements'].toString().replace(/<span style="color:green">/g, '').replace(/<\/span>/g, '');
                }
                // tslint:disable-next-line:no-shadowed-variable
                for (let i = 0; i < res.data.length; i++) {
                  // console.log(res.data[i]['rule']);
                  res.data[i]['sourcestatements'] = res.data[i]['sourcestatements'].toString().replace(/<br>/g, '\n');
                }
                this.dataSets = res;
                this.dataJson =[];
                this.dataJson = res.data;
                (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total results found: ' + res.displayed_count;
                // console.log(res.data.length);
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
                setTimeout(() => {
                    $('#xrefDataTblSummary td:first-child').each(function(i) {
                        $(this).addClass('highlight');
                    });
                }, 1100);
                setTimeout(() => {
                    const tableContd = document.querySelector('#table-contd');
                    function scrollHandle (e) {
                        const scrollTop = this.scrollTop;
                        this.querySelector('thead').style.transform = 'translateY(' + scrollTop + 'px)';
                    }
                    tableContd.addEventListener('scroll', scrollHandle);
                }, 1100);
                (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
                this.showLoader = false;
            });
        } else if(this.searchFilter===''){
            alert('Please enter a value to search');
        }
    }
    clearFilter() {
        (document.getElementById('searchFilter') as HTMLInputElement).value = '';
        return false;
    }
    showDetialed(){
        this.showSummaryView = true;
        this.showDetialedView = false;
        this.filterTable();
        // this.filterTblDetail();
    }
    showSummary(){
        this.showSummaryView = false;
        this.showDetialedView = true;
        // this.filterTableSummaryView(false);
        // this.filterTblDetail();
        this.filterTblDetailFromDetail();
    }
    filterTblDetailFromDetail() {
        this.showLoader = true;
        this.compNameList=[];
        for(var i=0; i<this.dataJson.length; i++){
            // console.log(this.dataJson[i]);
            if(this.compNameList.indexOf(this.dataJson[i].component_name + ',' +
                this.dataJson[i].component_type)===-1) {
                    this.compNameList.push(this.dataJson[i].component_name + ',' +
                        this.dataJson[i].component_type);
            }
        }
        // console.log(this.compNameList);
        var responseformatData = [];
        this.compNameList.forEach(function(arrayItem, idx, array) {
            var responseformatDataJSON = {};
            var count = 0;
            var componentName = arrayItem.split(",")[0];
            var componentType = arrayItem.split(",")[1];
            // for(var i=0; i<this.dataJson.length; i++){
            //     if(componentName.indexOf(this.dataJson[i].component_name)>0)
            //         count++;
            // }
            responseformatDataJSON['component_name'] = componentName;
            responseformatDataJSON['component_type'] = componentType;
            responseformatDataJSON['count'] = count;
            responseformatData.push(responseformatDataJSON);
        });
        var count=0;
        for(var i=0;i<responseformatData.length;i++){
            for(var j=0;j<this.dataJson.length;j++){
                if(responseformatData[i].component_name === this.dataJson[j].component_name){
                    responseformatData[i].count = responseformatData[i].count + 1;
                }
            }
        }
        var displayedCount = 0;
        for(var i=0;i<responseformatData.length;i++){
            displayedCount = displayedCount + responseformatData[i].count;
        }
        var resposeformatHeaders = ["component_name", "component_type", "count"];
        var finalJSON;
        finalJSON = {"data": responseformatData, "headers" : resposeformatHeaders, "displayed_count" : displayedCount};
        // console.log(finalJSON);
        this.dataJson = [];
        this.showExcel = true;
        this.dataSets = finalJSON;
        var dataJSON = {};
            var dataList = [];
            var headerList = finalJSON.headers;
            for(var i=0;i<finalJSON.data.length;i++){
                for(var j=0;j<headerList.length;j++){
                    dataJSON[headerList[j]] = finalJSON.data[i][headerList[j]];
                }
                dataList.push(dataJSON);
                dataJSON= {};
            }
            // console.log(dataList);
          this.excelDataSet = dataList;
        // this.excelDataSet = finalJSON.data;
        (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total results found: ' + finalJSON.displayed_count;
        setTimeout(() => {
            $('#xrefDataTbl td:first-child').each(function(i) {
                $(this).addClass('highlight');
            });
        }, 1100);
        setTimeout(() => {
            const tableCont = document.querySelector('#table-cont');
                function scrollHandled (e) {
                    const scrollTop = this.scrollTop;
                    this.querySelector('thead').style.transform = 'translateY(' + scrollTop + 'px)';
                }
                tableCont.addEventListener('scroll', scrollHandled);
        }, 1100);
        (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
        this.showLoader = false;
    }

    showExpandedCode() {
        (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
        (document.getElementById('canvasCode') as HTMLInputElement).style.height = '0%';
        (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'visible';
        (document.getElementById('expandedCode') as HTMLInputElement).style.height = '100%';

        (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = true;
        (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = false;
        console.log(this.compLine);
        this.dataservice.getExpandedComponentCodeWithScroll(this.compName, this.component_type, this.compLine).subscribe(res => {
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
            setTimeout(() => {
              const elmnt = document.getElementById('ExpCanvasScroll');
              try {
                elmnt.scrollIntoView();
              } catch (e) {
                console.log(e + 'Line not found');
              }
            }, 1100);
        }, error => {
          this.errormessage = 'Code not available for current component';
          (document.getElementById('expandedCode') as HTMLInputElement).innerHTML = this.errormessage;
      });
      }
      showCode() {
        (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
        (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
        (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'visible';
        (document.getElementById('canvasCode') as HTMLInputElement).style.height = '100%';
        (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
        (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;
        setTimeout(() => {
          const elmnt = document.getElementById('canvasScroll');
          try {
            elmnt.scrollIntoView();
          } catch (e) {
            console.log(e + 'Line not found');
          }
        }, 1100);
      }
    searchFilterOnChange(searchValue) {
      inputJson[0].variableSearchFiler = searchValue;
      if (searchValue.length >= 3) {
        (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
      } else {
        (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
      }
    }
}
