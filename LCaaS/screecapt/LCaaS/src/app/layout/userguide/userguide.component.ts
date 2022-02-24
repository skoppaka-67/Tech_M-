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


interface FileReaderEventTarget extends EventTarget {
  result: string;
}

interface FileReaderEvent extends Event {
  target: FileReaderEventTarget;
  getMessage():string;
}

@Component({
    selector: 'app-charts',
    templateUrl: './userguide.component.html',
    styleUrls: ['./userguide.component.scss'],
    animations: [routerTransition()]
})

export class UserGuideComponent implements OnInit {

    @Input() name: string;
    constructor() {}
    pdfSrc;

    ngOnInit() {
      window.scrollTo(0, 0);
      this.pdfSrc = "assets/pdf/LCaaS_User_Guide.pdf";
      // this.pdfSrc = "assets/pdf/werner_user_guide.pdf";
    }
    openPdf() {
      window.open(this.pdfSrc);
  }
}

