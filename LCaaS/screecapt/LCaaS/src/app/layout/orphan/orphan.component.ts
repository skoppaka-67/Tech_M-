import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';


@Component({
    selector: 'app-orphan',
    templateUrl: './orphan.component.html',
    styleUrls: ['./orphan.component.scss'],
    animations: [routerTransition()]
})
export class OrphanComponent implements OnInit {
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
        order: [ 0, 'asc'],
        searching : true,
        scrollY : '350',
        scrollX : true
      };
        this.getOrphanDetails();
      // console.log(this.dataSets);
    }
    getOrphanDetails() {
      this.showLoader = true;
        this.dataservice.getOrphanDetails().subscribe(res => {
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
            this.showLoader = false;
            console.clear();
          setTimeout(() => {
            $( $('#orphanDataTbl').DataTable().column(0).nodes()).addClass('highlight');
        }, 1100);
            this.dtTrigger.next();
           // console.log(this.dataSets);
        });
    }
    exportAsXLSX(): void {
      this.excelService.exportAsExcelFile(this.excelDataSet, 'Orphan Report');
     }
     open(content, compName, header, compTypeObj) {
      if (header === 'COMPONENT_NAME' || header === 'component_name') {
      //  alert(flowName.name);
        this.modalService.open(content, compName);
        (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
        (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
        (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
        (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true; 
        this.compName = compName;
      //   (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
      //   (document.getElementById('contentBody') as HTMLInputElement).innerText =
      //     'Component Name: ' + this.compName + '\n' +
      //     'Component Type: ' + compTypeObj['component_type'] + '\n' +
      //     'Code will be displayed below.';
      this.component_type = compTypeObj['component_type'];
          this.dataservice.getComponentCode(this.compName, compTypeObj['component_type']).subscribe(res => {
              this.codeString = res.codeString;
             /* this.codeString = this.codeString
              .replace(/\"/g, '"')
              .replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
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
              // const cblKeyword = JSON.parse(this.cobolKeywords);
              // // tslint:disable-next-line:forin
              // for (const key in cblKeyword.keywords) {
              // const replaceString = cblKeyword.keywords[key].toString().toLowerCase();
              //     this.codeString = this.codeString
              //     .replace(new RegExp(cblKeyword.keywords[key], 'gi'), '<span style="color: blue;">' + replaceString + '</span>');
              // }
              // console.log((document.getElementById('canvasCode') as HTMLInputElement));
              if(this.codeString!=undefined){
                (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.codeString;
                (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
              } else {
                this.errormessage = 'Code not available for current component';
                (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
              }
          }, error => {
            this.errormessage = 'Code not available for current component';
            (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
    });
      }
    }
    showExpandedCode(){
      (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
      (document.getElementById('canvasCode') as HTMLInputElement).style.height = '0%';
      (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'visible';
      (document.getElementById('expandedCode') as HTMLInputElement).style.height = '100%';
    
      (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = true;
      (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = false;
    
      this.dataservice.getExpandedComponentCode(this.compName, this.component_type).subscribe(res => {
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
