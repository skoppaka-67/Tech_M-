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
// import * as google from '../charts/loader';
import { ChartsModule as Ng2Charts } from 'ng2-charts';
// declare var flowchart: any;

interface FileReaderEventTarget extends EventTarget {
  result: string;
}

interface FileReaderEvent extends Event {
  target: FileReaderEventTarget;
  getMessage():string;
}

@Component({
    selector: 'app-charts',
    templateUrl: './charts.component.html',
    styleUrls: ['./charts.component.scss'],
    animations: [routerTransition()]
})

export class ChartsComponent implements OnInit {
  content2:string;
    @Input() name: string;
    constructor(
      public dataservice: DataService, config: NgbModalConfig,
      private modalService: NgbModal ) {
  }
  ngOnInit(){
   

  } 
  showJDL(jhippy){
    this.modalService.open(jhippy);
  }  
}

