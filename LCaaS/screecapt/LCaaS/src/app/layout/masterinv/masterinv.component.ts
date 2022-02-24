import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { Subject } from 'rxjs';
import { DataTableDirective } from 'angular-datatables';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';

@Component({
    selector: 'app-masterinv',
    templateUrl: './masterinv.component.html',
    styleUrls: ['./masterinv.component.scss'],
    animations: [routerTransition()]
})

export class MasterinvComponent implements OnInit {
  constructor(
    public dataservice: DataService,
    public excelService: ExcelService,
    config: NgbModalConfig,
    private modalService: NgbModal) {}

  title = 'app';
  showLoader = false;
  dataSets: any[] = [];
  excelDataSet: any[] = [];
  dtOptions: DataTables.Settings = {};
  dtElement: DataTableDirective;
  dtTrigger: Subject<any> = new Subject();
  compName = '';
  codeString = '';
  errormessage = '';
  component_type: string;
  componentTypeList: any[] = [];
  selectedComponent_Type ='';
  // keywordList = keywordJson.keywords;
  // tslint:disable-next-line:max-line-length
  // cobolKeywords = '{" keywords" : ["  DISPLAY " , "  ACCEPT " , "  INITIALIZE " , "  EXIT "  , " IF " , " ELSE " , " END " , " EVALUATE " , " ADD " , " SUBTRACT " , " MULTIPLY " , " DIVIDE " , " COMPUTE " , " MOVE " , " INSPECT " , " TALLYING " , " REPLACING " , " STRING " , " UNSTRING " , " SET " , " SEARCH " , " SEARCH-ALL " , " OPEN " , " CLOSE " , " READ " , " WRITE " , " REWRITE " , " DELETE " , " START " , " CALL " , " PERFORM " , " THRU " , " UNTIL " , " TIMES " , " VARYING " , " GO TO " , " STOP" , " RUN " , " GOBACK " , " SORT " , " MERGE " , " EXEC " , " SQL " , " SELECT " , " UPDATE " , " INSERT " , " FETCH " , " CICS " , " SEND " , " TEXT " , " FROM " , " MAP " , " MAPSET " , " RETURN " , " TRANSID " , " COMMAREA " , " LENGTH " , " RECEIVE " , " INTO " , " EVALUATE " , " EIBAID " , " WHEN " , " XCTL " , " LOAD " , " PROGRAM " , " RELEASE " , " ASKTURN " , " ABSTIME " , " DATESEP " , " FORMATTIME " , " WRITEQ " , " DELETEQ " , " QUEUE " , " READQ " , " STARTBR " , " READPREV " , " READNEXT " , " RIDFLD " , " KEYLENGTH " , " GTEQ " , " EQUAL " , " GENERIC " , " HANDLE " , " CONDITION " , " ERROR " , " ABEND " , " LABEL " , " CANCEL " , " RESET " , " ABCODE " , " IGNORE " , " NOHANDLE " , " USING " , " ENTRY " , " CONTINUE " , " NEXT " , " SENTENCE " ]}';
  ngOnInit() {
    window.scrollTo(0, 0);
    this.dtOptions =  {
      pagingType: 'full_numbers' ,
      paging : true,
      deferRender : false,
      // search : true,
      // ordering : true,
      // order: [ 0, 'asc'],
      // searching :true,
      scrollY : '350',
      scrollX : true
    };
    // this.getComponentTypeListMaster();
     this.getMasterInvenDetails();
    // console.log(this.keywordList);
}
getComponentTypeListMaster() {
  this.dataservice.getComponentTypeListMaster().subscribe(res => {
    this.componentTypeList = res;
  });
}
compTypeOnchange (event: any) {
  this.selectedComponent_Type = event.target.value;
}

onSubmit() {
  if (this.selectedComponent_Type === '') {
    
  } else {
    this.showLoader = true;
    this.dataservice.getMasterInvenDetailsWithApplicationFilter(this.selectedComponent_Type).subscribe(res => {
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
      this.showLoader = false;
      setTimeout(() => {
            $( $('#masterinv').DataTable().column(0).nodes()).addClass('highlight');
        }, 1100);
    }, error => {
      console.log(error);
    });
  }
}
  getMasterInvenDetails() {
    this.showLoader = true;
      this.dataservice.getMasterInvenDetails().subscribe(res => {
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
        // console.log(res.data);
        this.dtTrigger.next();
        this.showLoader = false;
        setTimeout(() => {
              $( $('#masterinv').DataTable().column(0).nodes()).addClass('highlight');
          }, 1100);
      }, error => {
        console.log(error);
      });
  }
  getValueorLink(header: any, value: any) {
    return header === 'component_name' ? '<a href="www.google.com">' + value + '</a>' : value;
    // private modalService: NgbModal
  }
  exportAsXLSX(): void {
    // this.dataservice.getMasterInvenDetailsWithApplicationFilter('all').subscribe(res => {
    //   this.excelService.exportAsExcelFile(res.data, 'Master Inventory Report');
    // });
    this.excelService.exportAsExcelFile(this.excelDataSet, 'Master Inventory Report');
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
          /*this.codeString = this.codeString
            .replace(/\"/g, '"')
            .replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
            .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
            .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
            .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
            .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
            .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
            .replace(/  /g, '&nbsp;&nbsp;')
            .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;')
            .replace(/\t\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');*/
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
          //   const replaceString = cblKeyword.keywords[key].toString().toLowerCase();
          //     this.codeString = this.codeString
          //     .replace(new RegExp(cblKeyword.keywords[key], 'gi'), '<span style="color: blue;">' + replaceString + '</span>');
          // }
          if(this.codeString!=undefined){
            (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.codeString;
            (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
          } else {
            this.errormessage = 'Code not available for current component';
            (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
          }
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
      //this.codeString = this.codeString
      /* .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
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

