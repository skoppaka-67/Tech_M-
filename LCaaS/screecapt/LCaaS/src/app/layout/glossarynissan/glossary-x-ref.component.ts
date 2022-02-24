import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';

@Component({
    selector: 'app-x-ref',
    templateUrl: './glossary-x-ref.component.html',
    styleUrls: ['./glossary-x-ref.component.scss'],
    animations: [routerTransition()]
})
export class GlossaryXrefComponent implements OnInit {
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
    selectedComponent = '';
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
    component_type: string;
 
    ngOnInit() {
    window.scrollTo(0, 0);
    this.getGlossaryDetails('', 'no', true);
      const tableCont = document.querySelector('#table-cont');
        function scrollHandle (e) {
            const scrollTop = this.scrollTop;
            this.querySelector('thead').style.transform = 'translateY(' + scrollTop + 'px)';
        }
        tableCont.addEventListener('scroll', scrollHandle);
    }
    getGlossaryDetails(searchFilter: string, overrideFilter, intializeTable: boolean) {
        if (intializeTable) {
          this.showLoader = true;		
          this.dataservice.getGlossaryDetailsXref(searchFilter, overrideFilter).subscribe(res => {		
              this.dataSets = res;		
              this.excelDataSet = res.data;
              this.showLoader = false;			
              document.getElementById('totalrecords').innerHTML =  'Total no of records: ' + res.total_record_count
              this.dtTrigger.next();
            });
        } else {
          this.showLoader = true;		
          this.dataservice.getGlossaryDetailsXref(searchFilter, overrideFilter).subscribe(res => {		
              this.dataSets = res;		
              this.excelDataSet = res.data;
              document.getElementById('totalrecords').innerHTML = 'Total no of records: ' + res.total_record_count;
              this.showLoader = false;			
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
        // this.excelService.exportAsExcelFile(this.excelDataSet, 'Glossary Report');
        this.dataservice.getGlossaryDetailsXref('', 'yes').subscribe(res => {				
            this.excelService.exportAsExcelFile(res.data, 'Glossary Report');
          });
      }

    filterTable() {
        this.searchFilter = (document.getElementById('searchFilter') as HTMLInputElement).value;
        if (this.searchFilter.length > 2) {
            (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
            (document.getElementById('clearButton') as HTMLInputElement).disabled = true;
            this.showLoader = true;
            this.dataservice.getGlossaryDetailsXref(this.searchFilter, 'no').subscribe(res => {
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
        this.getGlossaryDetails('', 'no', true);
        return false;
    }
}
