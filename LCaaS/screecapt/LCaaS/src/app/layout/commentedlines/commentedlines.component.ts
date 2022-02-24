import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';


@Component({
    selector: 'app-orphan',
    templateUrl: './commentedlines.component.html',
    styleUrls: ['./commentedlines.component.scss'],
    animations: [routerTransition()]
})

export class CommentedLinesComponent implements OnInit {
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
  dtElement: DataTableDirective;
  dtTrigger: Subject<any> = new Subject();
  compName = '';
  codeString = '';
  errormessage = '';
  showLoader = false;
  component_type: string;
    
  ngOnInit() {
    window.scrollTo(0, 0);
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
    this.getCommentedLinesDetail();
  }
  
  getCommentedLinesDetail() {
    this.showLoader = true;
    this.dataservice.getCommentedLinesDetails().subscribe(res => {
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
