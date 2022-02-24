import { Component, OnInit, ViewChild } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import * as inputJson from '../input.json';

@Component({
    selector: 'app-commentedlinesapp',
    templateUrl: './commentedlines-application.component.html',
    styleUrls: ['./commentedlines-application.component.scss'],
    animations: [routerTransition()]
})

export class CommentedLinesAppComponent implements OnInit {
  constructor(
    public dataservice: DataService,
    public excelService: ExcelService,
    config: NgbModalConfig,
    private modalService: NgbModal) {
    config.backdrop = 'static';
    config.keyboard = false;
  }
  dataSets: any = null;
  excelDataSet: any[] = [];
  dtOptions: DataTables.Settings = {};
  @ViewChild(DataTableDirective)
  dtElement: DataTableDirective;
  dtTrigger: Subject<any> = new Subject();
  compName = '';
  codeString = '';
  errormessage = '';
  showLoader = false;
  component_type: string;
  applicationTypeList: any[] = [];
  selectedApplication='';

  ngOnInit() {
    window.scrollTo(0, 0);
    // this.getAppList();
    this.dtOptions =  {
      pagingType: 'full_numbers' ,
      paging : true,
      search : true,
      ordering : true,
      order: [],
      searching : true,
      scrollY : '350',
      scrollX : true
    };
    this.getCommentedLinesDetail('',true);
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
    this.getCommentedLinesDetail(this.selectedApplication, false);
  }
  getCommentedLinesDetail(selectedApplication, initalizeTbl: boolean) {
    if(initalizeTbl){
      this.showLoader = true;
      this.dataservice.getCommentedLinesDetailsWithApp('').subscribe(res => {
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
        // this.excelDataSet = res.data;
        this.showLoader = false;
        console.clear();
        setTimeout(() => {
          $( $('#commentDataTbl').DataTable().column(0).nodes()).addClass('highlight');
        }, 1100);
        this.dtTrigger.next();
      });
    } else {
      this.showLoader = true;
      if(this.selectedApplication.indexOf('&')!=-1){
        this.selectedApplication = this.selectedApplication.replace('&','$');
      }
    this.dataservice.getCommentedLinesDetailsWithApp(this.selectedApplication).subscribe(res => {
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
      // this.excelDataSet = res.data;
      this.showLoader = false;
      console.clear();
      setTimeout(() => {
        $( $('#commentDataTbl').DataTable().column(0).nodes()).addClass('highlight');
      }, 1100);
      // this.dtTrigger.next();
      this.rerender();
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
    this.excelService.exportAsExcelFile(this.excelDataSet, 'Commented Lines Report');
  }
  
  open(content, compName, header, compTypeObj) {
      if (header === 'COMPONENT_NAME' || header === 'component_name') {
        this.modalService.open(content, compName);
        this.compName = compName;
        this.component_type = compTypeObj['component_type'];
          this.dataservice.commentcomponentcode(this.compName, compTypeObj['component_type']).subscribe(res => {
            this.codeString = res.commented_lines;
            if(this.codeString === ''){
              this.errormessage = 'Code not available for current component';
              (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
            } else {
              (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.codeString;
              (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
           }
          }, error => {
            this.errormessage = 'Code not available for current component';
            (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
        });
      }
    }
}
