import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import * as shape from 'd3-shape';
import { DataService } from '../data.service';
import { Directive, HostListener } from '@angular/core';
import { Edge, Node, ClusterNode, Layout } from '@swimlane/ngx-graph';
import {PrintService} from '../../print.service';
import * as domtoimage from 'dom-to-image';

@Component({
    selector: 'app-callchain-plsql',
    templateUrl: './callchainplsql.component.html',
    styleUrls: ['./callchainplsql.component.scss'],
    animations: [routerTransition()]
})
export class CallChainPLSQLComponent implements OnInit {

  constructor(public dataservice: DataService, public printService: PrintService ) {}

  title = 'Call Chain Diagram';
  hierarchialGraph = { nodes: [], links: [], label: [] };
  curve = shape.curveBundle.beta(1);
  layout: String = 'colaForceDirected';
  componentList: any[] = [];
  componentTypeList: any[] = [];
  selectedComponent_Name = '';
  selectedComponent_Type = '';
  selectedLevel = '';
  comp_type = '';
  view = [5000, 2000];
  selectedType = '';
  listValues = '';
  programNames = '';
  selectedProgram = '';
  selectedList = '';
  selectedFilter = '';
  filterList: any[] = [];
  
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

  fileTypeOnChange(event: any){
    this.getList(event.target.value);
    this.selectedType = event.target.value;
  }

  listOnChange(event: any){
    this.getProgramNames(event.target.value);
    this.selectedList = event.target.value;
  }

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

  programNamesOnchange(event: any) {
    if (event.target.value === '') {
      this.selectedProgram = '';
      (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
    } else {
      this.selectedProgram = event.target.value;
      (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
    }
  }

  compTypeOnchange (event: any) {
    this.getComponentName(event.target.value);
    this.selectedComponent_Type = event.target.value;
  }

  levelOnchange(event: any){
    this.selectedLevel = event.target.value;
  }

  filterOnchange(event: any){
    this.selectedFilter = event.target.value;
  }

  compNameOnchange(event: any) {
    this.selectedComponent_Name = event.target.value;
    this.getFilter(this.selectedComponent_Name, this.selectedComponent_Type);
  }

  getFilter(selectedCompName, selectedCompType){
    if(selectedCompName === '' || selectedCompType ==='') {
    } else {
      this.dataservice.getCallChainFilter(selectedCompName, selectedCompType).subscribe(res => {
        this.filterList = res;
      });
    }
  }

  onSubmit() {
    if (this.selectedComponent_Name === '' || this.selectedComponent_Type === '' 
        || this.selectedLevel === '' || this.selectedFilter === '') {
          this.hierarchialGraph = {nodes: [], links: [], label: [] };
          (document.getElementById('spiderErrMsg') as HTMLInputElement).style.visibility = 'visible';
          (document.getElementById('spiderErrMsg') as HTMLInputElement).style.color = 'red';
          (document.getElementById('spiderErrMsg') as HTMLInputElement).innerHTML = 'Please select all values';
      } else {
      if(this.selectedComponent_Name.indexOf('&')!=-1) {
        this.selectedComponent_Name = this.selectedComponent_Name.replace('&','$');
      }
      if(this.selectedComponent_Name.indexOf('&&')!=-1) {
        this.selectedComponent_Name = this.selectedComponent_Name.replace('&&','$$');
      }
      this.dataservice.getPLSQLSpiderFlow(this.selectedComponent_Name.replace('+', '%2B'),
      this.selectedComponent_Type.replace('+', '%2B'), this.selectedLevel, this.selectedFilter).subscribe(res => {
        if (res.nodes.length !== 0) {
          (document.getElementById('spiderErrMsg') as HTMLInputElement).style.visibility = 'hidden';
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
