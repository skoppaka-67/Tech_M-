import { Component, OnInit, ViewChild } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import { ExcelService } from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import * as XLSX from 'xlsx';
import Json from '*.json';

@Component({
  selector: 'app-bre',
  templateUrl: './glossary.component.html',
  styleUrls: ['./glossary.component.scss'],
  animations: [routerTransition()]
})

export class GlossaryComponent implements OnInit {

  constructor(
    public dataservice: DataService, public excelService: ExcelService, config: NgbModalConfig, 
      private modalService: NgbModal) {
        config.backdrop = 'static';
        config.keyboard = false;
  }

  title = 'BRE Report';
  componentList: any[] = [];
  selectedComponent = '';
  dataSets: any = null;
  excelDataSet: any[] = [];
  dtOptions: DataTables.Settings = {};
  @ViewChild(DataTableDirective)
  dtElement: DataTableDirective;
  element: HTMLElement;
  dtTrigger: Subject<any> = new Subject();
  showLoader = false;
  compName = '';
  codeString = '';
  errormessage = '';
  userId: boolean;

  ngOnInit(): void {
    window.scrollTo(0, 0);
    const userLoggedIn = sessionStorage.getItem('id');
    if (userLoggedIn === 'lcaasadmin') {
        this.userId = true;
    } else if (userLoggedIn === 'admin') {
        this.userId = false;
    }
    this.dtOptions =  {
      pagingType: 'full_numbers' ,
      paging : true,
      search : true,
      // ordering : true,
      order: [],
      autoWidth : false,
      columnDefs: [
          { 'width': '30%', 'targets': 0 },
          { 'width': '30%', 'targets': 1 },
          { 'width': '40%', 'targets': 2 },
        ],
      // searching :true,
      scrollY : '280',
      scrollX : true
    };
    // (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
    this.getGlossaryDetails(true);
    // (document.getElementById('uploadMsg') as HTMLInputElement).style.visibility = 'hidden';
    // (document.getElementById('uploadBtn') as HTMLInputElement).disabled = true;
    this.loadFields();
  }

  getGlossaryDetails(intializeTable: boolean) {
    if (intializeTable) {
      this.showLoader = true;		
      // this.dataservice.getGlossaryDetails().subscribe(res => {	
        this.dataservice.getGlossaryDetails_limit("no").subscribe(res => {	
          this.dataSets = res;		
          // this.excelDataSet = res.data;
          var dataJSON = {};
              var dataList = [];
              var headers = res.headers;
              for(var i=0;i<res.data.length;i++){
                  headers.forEach(function(header){
                    dataJSON[header] = res.data[i][header]
                  });
                  dataList.push(dataJSON);
                  dataJSON = {};
              } 
  
          this.excelDataSet = dataList;
          this.showLoader = false;			
          this.dtTrigger.next();
        });
    } else {
      this.showLoader = true;		
      // this.dataservice.getGlossaryDetails().subscribe(res => {		
        this.dataservice.getGlossaryDetails_limit("no").subscribe(res => {	
          this.dataSets = res;		
          // this.excelDataSet = res.data;
          var dataJSON = {};
              var dataList = [];
              var headers = res.headers;
              for(var i=0;i<res.data.length;i++){
                  headers.forEach(function(header){
                    dataJSON[header] = res.data[i][header]
                  });
                  dataList.push(dataJSON);
                  dataJSON = {};
              } 
  
          this.excelDataSet = dataList;
          
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
    this.dataservice.getGlossaryDetails_limit("yes").subscribe(res => {	
      // this.dataservice.getGlossaryDetails().subscribe(res => {		
        var dataJSON = {};
        var dataList = [];
        var headers = res.headers;
        console.log("length",res.data.length);
        for(var i=0;i<res.data.length;i++){
            headers.forEach(function(header){
              dataJSON[header] = res.data[i][header]
            });
            dataList.push(dataJSON);
            dataJSON = {};
        } 
        this.excelDataSet = dataList;
        this.excelService.exportAsExcelFile(this.excelDataSet, 'Glossary Report');
   });
  }
  open(content) {
    this.modalService.open(content);
    this.compName = this.selectedComponent;
    (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
    this.dataservice.getComponentCode(this.compName, 'COBOL').subscribe(res => {
      this.codeString = res.codeString;
      this.codeString = this.codeString
        .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
        .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
        .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
        .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
        .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
        .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
        .replace(/  /g, '&nbsp;&nbsp;')
        .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');
      document.getElementById('canvasCode').innerHTML = this.codeString;
      (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
    }, error => {
      this.errormessage = 'Code not available for current component';
      (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
    });
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
        this.getGlossaryDetails(false);
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



