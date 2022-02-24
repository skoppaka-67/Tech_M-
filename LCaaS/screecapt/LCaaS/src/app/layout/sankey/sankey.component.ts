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
import * as d3 from 'd3';
// declare var d3: any;
import * as inputJson from '../input.json';


interface FileReaderEventTarget extends EventTarget {
  result: string;
}

interface FileReaderEvent extends Event {
  target: FileReaderEventTarget;
  getMessage():string;
}

@Component({
    selector: 'app-sankey',
    templateUrl: './sankey.component.html',
    styleUrls: ['./sankey.component.scss'],
    animations: [routerTransition()]
})

export class SankeyComponent implements OnInit {

  title = '';
  type = '';
  data = [];
  columnNames = [];
  options = {};
  width = 0;
  height = 0;
  applicationTypeList: any[] = [];
  selectedApplication = '';
  selectedIntegrartion = '';

    @Input() name: string;
    constructor(public dataservice: DataService) {}
    ngOnInit() {
      window.scrollTo(0, 0);
      // this.applicationList();
      this.title = '';
      this.type = 'Sankey';
      this.data = [[]];

      /*[["Brazil","Portugal",1000],
          ["Brazil","France",400],
          ["Brazil","Spain",1],
          ["Brazil","England",300]];*/
      this.columnNames = ['From', 'To','Weight'];
      this.options = {

        sankey: {
          node: {
              nodePadding: 30,
              labelPadding: 20,
              label: {
                  fontSize: 18,
                  bold: true,
              }
          },
          link: {
              color: {
                stroke: '#aaaaaa',
                strokeWidth: 1
              }
          },
        }
      };
      this.width = 1000;
      this.height = 500;
      this.getLoadedValues();
  }
  getLoadedValues() {
    // console.log(inputJson[0], inputJson[0].appName);
    if ( inputJson[0].appName !== undefined && inputJson[0].appName !== '') {
      this.applicationList();
      setTimeout(() => {
        // (document.getElementById('appln') as HTMLInputElement).value = inputJson[0].appName;
        // this.selectedApplication = inputJson[0].appName;
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
          // document.getElementById('submitBtn').click();
          // this.getProgramNameList(inputJson[0].appName);
        }
        else {
          var mySelect = document.getElementById('appln') as HTMLSelectElement;
          mySelect.selectedIndex = 1;
          this.selectedApplication = (document.getElementById('appln') as HTMLInputElement).value;
          // document.getElementById('submitBtn').click();
          // this.getProgramNameList((document.getElementById('appln') as HTMLInputElement).value);
        }
        setTimeout(() => {
          (document.getElementById('pgmName') as HTMLInputElement).value = inputJson[0].sankey;
          this.selectedIntegrartion = inputJson[0].sankey;
            setTimeout(() => {
                document.getElementById('submitBtn').click();
            }, 500);
        }, 500);
      }, 500);
    } else {
      this.applicationList();
    }
  }
  applicationList() {
    this.dataservice.getApplicationList().subscribe(res => {
      this.applicationTypeList = res.application_list;
      console.clear();
  });
  }
  applicationTypeOnchange(event: any) {
    this.selectedApplication = event.target.value;
    inputJson[0].appName = event.target.value;
  }
  integrationOnchange(event: any){
    this.selectedIntegrartion = event.target.value;
    inputJson[0].sankey = event.target.value;
  }
  onSubmit(){
    if(this.selectedApplication.indexOf('&')!=-1){
      this.selectedApplication = this.selectedApplication.replace('&','$');
    }
      this.getSankey(this.selectedApplication, this.selectedIntegrartion);
  }
  getSankey(selectedApplication, selectedIntegrartion){
    this.dataservice.getSankeyDetails(selectedApplication, selectedIntegrartion).subscribe(res => {
      
      if (res.length === 0) {
        (document.getElementById("sankeyMSg") as HTMLElement).style.color = 'red';
        (document.getElementById("sankeyMSg") as HTMLElement).style.visibility = 'visible';
        (document.getElementById("sanekyChart") as HTMLElement).style.visibility = 'hidden';
        (document.getElementById("sankeyMSg") as HTMLElement).innerHTML = 'Integration could not be found for selected application.';
      } else {
        (document.getElementById("sankeyMSg") as HTMLElement).style.visibility = 'hidden';
        (document.getElementById("sanekyChart") as HTMLElement).style.visibility = 'visible';
        var len = res.length;
        if(len>20){
          this.height = 1500;
        }
        this.data = res;
      }
    });
  }
  download(){
    window.print(); 
  }
}

