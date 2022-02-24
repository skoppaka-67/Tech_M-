import { Component, OnInit, ViewChild } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';


@Component({
    selector: 'app-breplsql',
    templateUrl: './breplsql.component.html',
    styleUrls: ['./breplsql.component.scss'],
    animations: [routerTransition()]
})

export class BrePlSqlComponent implements OnInit {

  constructor(
    public dataservice: DataService,
    public excelService: ExcelService,
    config: NgbModalConfig,
    private modalService: NgbModal
) {
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
    applicationTypeList: any[] = [];
    programNameList: any[] = [];
    selectedApplication = '';
    selectedType = '';
    listValues = '';
    programNames = '';
    selectedProgram = '';
    selectedList = '';
    ngOnInit(): void {
      window.scrollTo(0, 0);
      this.dtOptions =  {
        pagingType: 'full_numbers',
        paging : true,
        search : true,
     //   ordering : true,
        order: [],
        autoWidth : false,
            columnDefs: [
                { 'width': '10%', 'targets': 0 },
                { 'width': '10%', 'targets': 1 },
                { 'width': '10%', 'targets': 2 },
                { 'width': '10%', 'targets': 3 },
                { 'width': '40%', 'targets': 4 },
                { 'width': '10%', 'targets': 5 }
              ],
       // searching :true,
        scrollY : '350',
        scrollX : true
      };
      (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
      // this.getComponentList();
      // this.applicationList();
     this.getBREDetailsNew('', '', '', true);
    }
    // getComponentList() {
    //   this.dataservice.getComponentList().subscribe(res => {
    //       this.componentList = res.program_list;
    //      // console.log(res);
    //   });
    // }
    // applicationList() {
    //   this.dataservice.getApplicationList().subscribe(res => {
    //     this.applicationTypeList = res.application_list;
    //     console.clear();
    // });
    // }
    fileTypeOnChange(event: any){
      this.getList(event.target.value);
      this.selectedType = event.target.value;
    }
    listOnChange(event: any){
      this.getProgramNames(event.target.value);
      this.selectedList = event.target.value;
    }
    // applicationTypeOnchange(event: any) {
    //   this.getProgramNameList(event.target.value);
    //   this.selectedApplication = event.target.value;
    // }
    // getProgramNameList(selectedApplication) {
    //   this.dataservice.getProgramNameList(selectedApplication).subscribe(res => {
    //     this.programNameList = res.component_list;
    // });
    // }
    getProgramNames(selectedList) {
      this.dataservice.getProgramNames(this.selectedType, selectedList).subscribe(res => {
        this.programNames = res.package_list.filter(Boolean);
    });
    }
    getList(selectedType){
      this.dataservice.getList(selectedType).subscribe(res => {
        this.listValues = res.package.filter(Boolean);
    });
    }
    // programNameOnchange(event: any) {
    //   if (event.target.value === '') {
    //     this.selectedComponent = '';
    //     (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
    // } else {
    //     this.selectedComponent = event.target.value;
    //     (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
    // }
    // }
    programNamesOnchange(event: any) {
      if (event.target.value === '') {
        this.selectedProgram = '';
        (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
    } else {
        this.selectedProgram = event.target.value;
        (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
    }
    }
    // onChange(component: string) {
    //   if (component === '') {
    //       this.selectedComponent = '';
    //       (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
    //   } else {
    //       this.selectedComponent = component;
    //       console.log('onchange');
    //       (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
    //   }
    // }
    onSubmit() {
      this.showLoader = true;
      this.getBREDetailsNew(this.selectedType, this.selectedList, this.selectedProgram, false);
      this.showLoader = false;
    }
    getBREDetailsNew(selectedType, selectedList, selectedProgram, intializeTable: boolean) {
      if (intializeTable) {
      this.dataservice.getBREPlSqlDetailsNew(selectedType, selectedList, selectedProgram).subscribe(res => {
        for (let i = 0; i < res.data.length; i++) {
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/<br>/g, '\n');
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/\n/g, '\n');
        }
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
            //console.log(dataList);

          this.excelDataSet = dataList;
          this.dtTrigger.next();
      });
    } else {
      this.dataservice.getBREPlSqlDetailsNew(selectedType, selectedList, selectedProgram).subscribe(res => {
        console.log(selectedType, selectedList, selectedProgram);
        for (let i = 0; i < res.data.length; i++) {
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/<br>/g, '\n');
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/\n/g, '\n');
        }
          this.dataSets = res;
          console.log(res.headers);

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
            console.log(dataList);

          this.excelDataSet = dataList;
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
     this.excelService.exportAsExcelFile(this.excelDataSet, (document.getElementById('pgmName') as HTMLInputElement).value);
    }
    open(content) {
        this.modalService.open(content);
        (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
        (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
        (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
        (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;
        this.compName = this.selectedComponent;
        (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
        this.dataservice.getComponentCode(this.compName, 'COBOL').subscribe(res => {
          this.codeString = res.codeString;
         /* this.codeString = this.codeString
          .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
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
            document.getElementById('canvasCode').innerHTML = this.codeString;
            (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
        }, error => {
          this.errormessage = 'Code not available for current component';
          (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
  });
  }
  showExpandedCode(){
    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('canvasCode') as HTMLInputElement).style.height = '0%';
    (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'visible';
    (document.getElementById('expandedCode') as HTMLInputElement).style.height = '100%';
    (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = true;
    (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = false;
    this.dataservice.getExpandedComponentCode(this.compName, 'COBOL').subscribe(res => {
      this.codeString = res.codeString;
      /*this.codeString = this.codeString
      .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
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



