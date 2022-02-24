import { Component, OnInit, Input } from '@angular/core';
import { routerTransition } from '../../router.animations';
import 'zone.js/dist/zone';
import { ViewChild } from '@angular/core';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import {ExcelService} from '../../excel.service';

@Component({
  selector: 'app-datamodel',
  templateUrl: './datamodel.component.html',
  styleUrls: ['./datamodel.component.scss'],
  animations: [routerTransition()]
})
export class DatamodelComponent implements OnInit {
  @Input() name: string;
  constructor(
    public dataservice: DataService, config: NgbModalConfig,
    public excelService: ExcelService, private modalService: NgbModal ) {
    config.backdrop = 'static';
    config.keyboard = false;
  }
  dataSets: any = null;
  dtOptions: DataTables.Settings = {};
  @ViewChild(DataTableDirective)
  dtElement: DataTableDirective;
  dtTrigger: Subject<any> = new Subject();
  url;
  excelDataSet: any;
  ngOnInit() {
    this.dtOptions =  {
      pagingType: 'full_numbers' ,
      paging : true,
      search : {
        smart: false,
        caseInsensitive : false,
      },
      order: [],
      autoWidth : false,
      scrollY : '350',
      scrollX : true
    };
  this.showDataModelReport();
    
  }
  showDataModelReport() {
    this.dataservice.showDataModelReport().subscribe(res => {
      this.dataSets  = res;
      this.excelDataSet = res.data;
      this.dtTrigger.next();
    });
  }
  showJDL(jhippy) {
    this.modalService.open(jhippy);
    document.getElementById('jhipsterJDL').innerHTML =
      // tslint:disable-next-line:max-line-length
      '<iframe src="https://start.jhipster.tech/jdl-studio/#!/view/3030d6d7-4d55-4835-9ca3-544381ae1b9e" style="visibility:visible;width:100%;height:100%;"' +
      'target="_parent"></iframe>';
  }
  launchApp(content) {
    // '<iframe src="http://13.127.220.12:8089/" style="visibility:visible;width:100%;height:100%;"' +
    // 'target="_parent" X-Frame-Options="allow"></iframe>';
    this.modalService.open(content);
    document.getElementById('jhipsterApp').innerHTML =
      '<iframe src="http://localhost:8089/" style="visibility:visible;width:100%;height:100%;"' +
      'target="_parent"></iframe>';
      // '<iframe src="http://13.127.220.12:8089/" style="visibility:visible;width:100%;height:100%;"' +
      // 'target="_parent"></iframe>';
      //http://lcaas.techm.name:5009/
      //http://localhost:8089/ 
    // this.url = 'http://13.127.220.12:8089/'; http://gitlab.techm.name:8089/ http://172.18.32.181:8090/
    // window.open(this.url, '_blank');
  }
  createApp(createApplication){
    this.modalService.open(createApplication);
  }
  // showPdf(pdfShow) {
  //   this.modalService.open(pdfShow);
  //   document.getElementById('pdfShow').innerHTML = '<embed src="../../../AP540P00.pdf" width="100%" height="100%"/>';
  // }
exportAsXLSX(): void {
    this.excelService.exportAsExcelFile(this.excelDataSet, 'Data Model Report');
  }
  
}
