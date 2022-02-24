import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { Directive, HostListener } from '@angular/core';
import { Edge, Node, ClusterNode, Layout } from '@swimlane/ngx-graph';
import { PrintService } from '../../print.service';
import * as domtoimage from 'dom-to-image';
import * as shape from 'd3-shape';

@Component({
  selector: 'app-batchflow',
  templateUrl: './batchflow.component.html',
  styleUrls: ['./batchflow.component.scss'],
  animations: [routerTransition()]
})
export class BatchFlowComponent implements OnInit {

  constructor(public dataservice: DataService, public printService: PrintService) {}

  title = 'Batch Flow Chart';
  hierarchialGraph = { nodes: [], links: [], label: [] };
  curve = shape.curveBundle.beta(1);
  layout: String = 'colaForceDirected';
  componentList: any[] = [];
  componentTypeList: any[] = [];
  selectedComponent_Name = '';
  selectedComponent_Type = '';
  selectedComponent_Name1 = '';
  selectedComponent_Type1 = '';
  comp_type = '';
  view = [5000, 2000];

  ngOnInit(): void {
    (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'hidden';
    this.getApplicationComponentTypeList();
  }

  @HostListener('dblclick') onDoubleClicked() {
    if (this.selectedComponent_Name === '' || this.selectedComponent_Type === '') {
      this.hierarchialGraph = {nodes: [], links: [], label: [] };
    } else {
      this.dataservice.getBatchFlow(this.selectedComponent_Name.replace('+', '%2B'),
      this.selectedComponent_Type.replace('+', '%2B')).subscribe(res => {
        this.hierarchialGraph = res;
      });
    }
  }

  getApplicationName(comp_type) {
    this.dataservice.getApplicationName(comp_type).subscribe(res => {
      this.componentList = res;
    });
  }

  getApplicationComponentTypeList() {
    this.dataservice.getApplicationComponentTypeList().subscribe(res => {
      this.componentTypeList = res;
    });
  }

  compTypeOnchange (event: any) {
    this.getApplicationName(event.target.value);
    this.selectedComponent_Type = event.target.value;
    this.selectedComponent_Type1 = event.target.value;
  }

  compNameOnchange(event: any) {
    this.selectedComponent_Name = event.target.value;
    this.selectedComponent_Name1 = event.target.value;
  }
  onSubmit() {
      if (this.selectedComponent_Name1 === '' || this.selectedComponent_Type1 === '') {
        this.hierarchialGraph = { nodes: [], links: [], label: [] };
      } else {
        this.dataservice.getBatchFlow(this.selectedComponent_Name1.replace('+', '%2B'),
        this.selectedComponent_Type1.replace('+', '%2B')).subscribe(res => {
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

  downloadChart() {
  }

  onClick(data): void {
    const _str = data.name.split(' (');
    this.selectedComponent_Name = _str[0].trim(); // res1[0];
    this.selectedComponent_Type = _str[1].replace(')', '').trim();
  }
  printData() {
    window.print();
  }
}
