import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import * as XLSX from 'xlsx';
import Json from '*.json';

@Component({
    selector: 'app-x-ref',
    templateUrl: './glossarytw-x-ref.component.html',
    styleUrls: ['./glossarytw-x-ref.component.scss'],
    animations: [routerTransition()]
})
export class GlossaryTWXrefComponent implements OnInit {
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
        this.loadFields();
    }
    loadFields(){
        $(document).ready(function() {
          $('#fileUploader').change(function(evt) {
            (document.getElementById('excelJson') as HTMLInputElement).innerHTML = '';
            // (document.getElementById('uploadMsg') as HTMLInputElement).style.visibility = 'hidden';
            if((<HTMLInputElement>document.getElementById('fileUploader')).files.length>0){
              // (document.getElementById('uploadMsg') as HTMLInputElement).style.visibility = 'visible';
              let selectedFile = (<HTMLInputElement>document.getElementById('fileUploader')).files[0];
              var validExts = new Array(".xlsx", ".xls");
              var fileExt = selectedFile.name;
              fileExt = fileExt.substring(fileExt.lastIndexOf('.'));
              if (validExts.indexOf(fileExt) < 0) {
                alert("Invalid file selected, valid files are of " +
                          validExts.toString() + " types.");
                (<HTMLInputElement>document.getElementById('fileUploader')).value = "";
                // (document.getElementById('uploadBtn') as HTMLInputElement).disabled = true;
              }
              else {
                // (document.getElementById('uploadMsg') as HTMLInputElement).style.visibility = 'hidden';
                // (document.getElementById('uploadBtn') as HTMLInputElement).disabled = false;
                var reader: FileReader = new FileReader();
                reader.onload = function(event: Event) {
                  var data = reader.result;
                  var workbook = XLSX.read(data, {
                    type: 'binary'
                  });
                  var first_sheet_name = workbook.SheetNames[0];
                  /* Get worksheet */
                  var worksheet = workbook.Sheets[first_sheet_name];
                  const jsonOp = XLSX.utils.sheet_to_json(worksheet, {
                      raw: true
                  });
                  // console.log(JSON.stringify(jsonOp));
                  (document.getElementById('excelJson') as HTMLInputElement).innerHTML = JSON.stringify(jsonOp);
                } 
                reader.onerror = function(event){
                  console.log("file could not be read");
                }
                reader.readAsBinaryString(selectedFile);
              }
            } else {
              // (document.getElementById('uploadBtn') as HTMLInputElement).disabled = true;
              (document.getElementById('uploadMsg') as HTMLInputElement).style.color = 'red';
              (document.getElementById('uploadMsg') as HTMLInputElement).style.visibility = 'visible';
              (document.getElementById('uploadMsg') as HTMLInputElement).innerHTML = 'Please attach a file to proceed.';
            }
          });
        });
      }
    getGlossaryDetails(searchFilter: string, overrideFilter, intializeTable: boolean) {
        if (intializeTable) {
          this.showLoader = true;		
          this.dataservice.getGlossaryDetailsXref(searchFilter, overrideFilter).subscribe(res => {		
              this.dataSets = res;		
              this.excelDataSet = res.data;
            console.log('Page loaded with:',res.data.length, 'records');
              this.showLoader = false;			
              document.getElementById('totalrecords').innerHTML =  'Total no of records: ' + res.total_record_count
              this.dtTrigger.next();
            });
        } else {
          this.showLoader = true;		
          this.dataservice.getGlossaryDetailsXref(searchFilter, overrideFilter).subscribe(res => {		
              this.dataSets = res;		
              this.excelDataSet = res.data;
              console.log('Page loaded with filtered:',res.data.length, 'records');
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
            console.log('Excel downloaded with:', res.data.length, 'records');
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
    updateDataBase(){
        var str = (document.getElementById('excelJson') as HTMLInputElement).innerHTML;
        (<HTMLInputElement>document.getElementById('fileUploader')).value ='';
    
        (document.getElementById('updateBtn') as HTMLInputElement).disabled = false;
        var result = str.substring(1, str.length-1);
        this.showLoader = true;
        (document.getElementById('uploadMsg') as HTMLInputElement).style.visibility = 'hidden';
        this.dataservice.sendExcelFileGlossary(result).subscribe(res => {
          if(res == 'success'){
            (document.getElementById('uploadMsg') as HTMLInputElement).style.color = 'green';
            (document.getElementById('uploadMsg') as HTMLInputElement).style.visibility = 'visible';
            (document.getElementById('uploadMsg') as HTMLInputElement).innerHTML = 'Success, Database has been updated.';
            this.showLoader = false;
            this.getGlossaryDetails('', 'no', false);
          } else if(res == 'failure'){
            this.showLoader = false;
            (document.getElementById('uploadMsg') as HTMLInputElement).style.color = 'red';
            (document.getElementById('uploadMsg') as HTMLInputElement).style.visibility = 'visible';
            (document.getElementById('uploadMsg') as HTMLInputElement).innerHTML = 'Failure, Database could not be updated.';
          }
        });
      }
      updateVariableInfo(){
        this.showLoader = true;
        (document.getElementById('updateBtn') as HTMLInputElement).disabled = true;
        this.dataservice.updateVariableDefinition().subscribe(res => {
          console.log(res);
          if(res == 'success'){
            (document.getElementById('uploadMsg') as HTMLInputElement).style.color = 'green';
            (document.getElementById('uploadMsg') as HTMLInputElement).style.visibility = 'visible';
            (document.getElementById('uploadMsg') as HTMLInputElement).innerHTML = 'Success, Annotations updated.';
            this.showLoader = false;
          } else if(res == 'failure'){
            this.showLoader = false;
            (document.getElementById('uploadMsg') as HTMLInputElement).style.color = 'red';
            (document.getElementById('uploadMsg') as HTMLInputElement).style.visibility = 'visible';
            (document.getElementById('uploadMsg') as HTMLInputElement).innerHTML = 'Failure, Annotations could not be updated.';
          }
        });
      }
      info() {
        var popup = document.getElementById("myPopup");
        popup.classList.toggle("show");
      }
}
