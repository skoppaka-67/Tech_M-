import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import * as shape from 'd3-shape';
import { DataService } from '../data.service';
import { Directive, HostListener } from '@angular/core';
import { Edge, Node, ClusterNode, Layout } from '@swimlane/ngx-graph';
import {PrintService} from '../../print.service';
import * as domtoimage from 'dom-to-image';

@Component({
    selector: 'app-spider',
    templateUrl: './controlflow.component.html',
    styleUrls: ['./controlflow.component.scss'],
    animations: [routerTransition()]
})
export class ControlFlowComponent implements OnInit {

  constructor(public dataservice: DataService, public printService: PrintService ) {}

  title = 'Spider Chart';
  hierarchialGraph = { nodes: [], links: [], label: [] };
  curve = shape.curveBundle.beta(1);
  // layout: String = 'colaForceDirected';
  componentList: any[] = [];
  componentTypeList: any[] = [];
  selectedComponent_Name = '';
  selectedComponent_Type = '';
  comp_type = '';
  view = [5000, 2000];
  ngOnInit(): void {
    window.scrollTo(0, 0);
    (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'hidden';
    this.getComponentTypeList();
  }

  getComponentName(comp_type) {
    this.dataservice.getComponentName(comp_type).subscribe(res => {
      this.componentList = res;
    });
  }

  getComponentTypeList() {
    this.dataservice.getComponentTypeList().subscribe(res => {
      this.componentTypeList = res;
    });
  }

  compTypeOnchange (event: any) {
    this.getComponentName(event.target.value);
    this.selectedComponent_Type = event.target.value;
  }

  compNameOnchange(event: any) {
    this.selectedComponent_Name = event.target.value;
  }
  onSubmit() {
    if (this.selectedComponent_Name === '' || this.selectedComponent_Type === '') {
      this.hierarchialGraph = {nodes: [], links: [], label: [] };
    } else {
      if(this.selectedComponent_Name.indexOf('#')!=-1) {
        this.selectedComponent_Name = this.selectedComponent_Name.replace('#','HASH');
      }
      if(this.selectedComponent_Name.indexOf('&')!=-1) {
        this.selectedComponent_Name = this.selectedComponent_Name.replace('&','$');
      }
      if(this.selectedComponent_Name.indexOf('&&')!=-1) {
        this.selectedComponent_Name = this.selectedComponent_Name.replace('&&','$$');
      }
      this.dataservice.getControlFlow(this.selectedComponent_Name.replace('+', '%2B'),
      this.selectedComponent_Type.replace('+', '%2B')).subscribe(res => {
        if (res.nodes.length !== 0) {
          (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'visible';
          (document.getElementById('spiderErrMsg') as HTMLInputElement).style.visibility = 'hidden';
          (document.getElementById('spiderDiag') as HTMLInputElement).style.visibility = 'visible';
          this.hierarchialGraph = res;
        } else {
          (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'hidden';
          (document.getElementById('spiderErrMsg') as HTMLInputElement).style.visibility = 'visible';
          (document.getElementById('spiderErrMsg') as HTMLInputElement).style.color = 'red';
          (document.getElementById('spiderErrMsg') as HTMLInputElement).innerText = 'Data not available for selected component!';
          (document.getElementById('spiderDiag') as HTMLInputElement).style.visibility = 'hidden';
        }
      });
    }
}
  printData() {
    window.print();
  }
}
