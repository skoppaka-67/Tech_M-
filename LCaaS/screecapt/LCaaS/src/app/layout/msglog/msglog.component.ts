import { Component, OnInit, Input } from '@angular/core';
import { routerTransition } from '../../router.animations';
import 'zone.js/dist/zone';
import { ViewChild } from '@angular/core';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import * as XLSX from 'xlsx';
import Json from '*.json';
import html2canvas from 'html2canvas';
import { ChartsModule as Ng2Charts } from 'ng2-charts';


@Component({
    selector: 'app-msglog',
    templateUrl: './msglog.component.html',
    styleUrls: ['./msglog.component.scss'],
    animations: [routerTransition()]
})

export class MsgLogComponent implements OnInit {
  
  showLoader = false;
  dataSets: any [] = [];
  excelDataSet: any[] = [];
  dtOptions: DataTables.Settings = {};
  dtElement: DataTableDirective;
  dtTrigger: Subject<any> = new Subject();

  @Input() name: string;
  constructor(public dataservice: DataService) {}
  
  ngOnInit(){
    window.scrollTo(0, 0);
    this.dtOptions =  {
      pagingType: 'full_numbers',
      paging : true,
      deferLoading: 10,
      search : true,
      ordering : true,
      order: [],
      searching : true,
      scrollY : '350',
      scrollX : true
    };
    this.getMsgLogDetails();
  } 
  getMsgLogDetails() {
    this.showLoader = true;
      this.dataservice.getMsgLogDetails().subscribe(res => {
          this.dataSets = res;
          this.excelDataSet = res.data;
          this.dtTrigger.next();
          this.showLoader = false;
      });
  }
}

