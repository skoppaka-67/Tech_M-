import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';

@Component({
    selector: 'app-missingcomp',
    templateUrl: './missingcomp.component.html',
    styleUrls: ['./missingcomp.component.scss'],
    animations: [routerTransition()]
})
export class MissingcompComponent implements OnInit {
    constructor(
        public dataservice:DataService,
        public excelService:ExcelService
    ) {}
    title = 'app';
    showLoader:boolean=false;
    //null; //
    dataSets:any[]= [];
    excelDataSet: any[] = []; 
    dtOptions: DataTables.Settings = {};
    dtElement: DataTableDirective;
    dtTrigger: Subject<any> = new Subject();
    ngOnInit(){
     // console.log(this.dataSets);
     window.scrollTo(0, 0);
      this.dtOptions =  {  
        pagingType: 'full_numbers' ,
        paging : true,
        search : true,
        ordering : true,
        order: [ 0, 'asc'], 
        searching :true,
        scrollY : '350',
        scrollX : true
      };
      this.getmissingcomponents();
    }
    getmissingcomponents(){
        this.showLoader = true;
        this.dataservice.getMissingComponents().subscribe(res=>{
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
            // console.log(dataList);
          this.excelDataSet = dataList;
            this.dtTrigger.next();
            this.showLoader = false;
          //  console.log(this.dataSets);
        })
    }
    exportAsXLSX():void {
        this.excelService.exportAsExcelFile(this.excelDataSet, 'Missing Component Report');
       }
}
