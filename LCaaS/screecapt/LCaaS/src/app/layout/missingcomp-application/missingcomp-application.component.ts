import { Component, OnInit, ViewChild } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import * as inputJson from '../input.json';

@Component({
    selector: 'app-missingcompapp',
    templateUrl: './missingcomp-application.component.html',
    styleUrls: ['./missingcomp-application.component.scss'],
    animations: [routerTransition()]
})
export class MissingcompAppComponent implements OnInit {
    constructor(
        public dataservice:DataService,
        public excelService:ExcelService
    ) {}
    title = 'app';
    showLoader:boolean=false;
    // null;
    dataSets: any[] = [];
    excelDataSet: any[] = [];
    dtOptions: DataTables.Settings = {};
    @ViewChild(DataTableDirective)
    dtElement: DataTableDirective;
    dtTrigger: Subject<any> = new Subject();
    applicationTypeList: any[] = [];
    selectedApplication = '';
    ngOnInit() {
     // console.log(this.dataSets);
     window.scrollTo(0, 0);
    //  this.getMissingAppList();
      this.dtOptions =  {
        pagingType: 'full_numbers' ,
        paging : true,
        search : true,
        ordering : true,
        order: [ 0, 'asc'],
        searching : true,
        scrollY : '350',
        scrollX : true
      };
      this.getmissingcomponentsApp('', true);
      this.getLoadedValues();
    }
    getLoadedValues() {
      // console.log(inputJson[0], inputJson[0].appName);
      if ( inputJson[0].appName !== undefined && inputJson[0].appName !== '') {
        this.getMissingAppList();
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
        this.getMissingAppList();
      }
    }
    getMissingAppList(){
        this.dataservice.getMissingAppList().subscribe(res => {
          this.applicationTypeList = res.application_list;
          // console.clear();
      });
      }
      applicationTypeOnchange(event: any){
        this.selectedApplication = event.target.value;
        inputJson[0].appName = event.target.value;
      }
      onSubmit(){
          this.showLoader = true;
          if(this.selectedApplication.indexOf('&')!=-1){
            this.selectedApplication = this.selectedApplication.replace('&','$');
          }
          this.getmissingcomponentsApp(this.selectedApplication, false);
          this.showLoader = false;
      }
      getmissingcomponentsApp(selectedApplication, intitializeTbl:boolean){
          if(intitializeTbl){
            this.showLoader = true;
            this.dataservice.getMissingComponentsWithApp('').subscribe(res=>{
                this.dataSets=res;
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
                this.excelDataSet = dataList;
                this.dtTrigger.next();
                this.showLoader = false;
            })
        } else {
            this.showLoader = true;
            if(this.selectedApplication.indexOf('&')!=-1){
                this.selectedApplication = this.selectedApplication.replace('&','$');
              }
            this.dataservice.getMissingComponentsWithApp(this.selectedApplication).subscribe(res=>{
                this.dataSets=res;
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
                this.excelDataSet = dataList;
                this.rerender();
                this.showLoader = false;
            })
        }
    }
    rerender(): void {
        this.dtElement.dtInstance.then((dtInstance: DataTables.Api) => {
          dtInstance.destroy();
          this.dtTrigger.next();
        });
      }
    exportAsXLSX():void {
        this.excelService.exportAsExcelFile(this.excelDataSet, 'Missing Component Report');
       }
}
