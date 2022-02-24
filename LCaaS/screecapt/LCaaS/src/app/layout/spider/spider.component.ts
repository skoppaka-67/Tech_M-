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
    templateUrl: './spider.component.html',
    styleUrls: ['./spider.component.scss'],
    animations: [routerTransition()]
})
export class SpiderComponent implements OnInit {

  constructor(public dataservice: DataService, public printService: PrintService ) {}

  title = 'Spider Chart';
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

  // layout: String | Layout = 'd3ForceDirected';
  ngOnInit(): void {
    window.scrollTo(0, 0);
    // this.showGraph();
    (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'hidden';
    this.getComponentTypeList();
  }

@HostListener('dblclick') onDoubleClicked() {
  // console.log('Double Click!');
  // this.getComponentName(this.selectedComponent_Type);
  // this.onSubmit();
 // console.log('dblclick: name:', this.selectedComponent_Name.replace('+', '%2B'),
   // 'dblclick: type:', this.selectedComponent_Type.replace('+', '%2B'));
  if (this.selectedComponent_Name === '' || this.selectedComponent_Type === '') {
    this.hierarchialGraph = {nodes: [], links: [], label: [] };
  } else {
    this.dataservice.getSpiderFlow(this.selectedComponent_Name.replace('+', '%2B'),
    this.selectedComponent_Type.replace('+', '%2B')).subscribe(res => {
      this.hierarchialGraph = res;
    });
  }
}

  // @HostListener('click') onClicked() {
  //   //console.log('single click!');
  //   return false;
  // }

  getComponentName(comp_type) {
    this.dataservice.getComponentName(comp_type).subscribe(res => {
      this.componentList = res;
      // console.log(res);
    });
  }

  getComponentTypeList() {
    this.dataservice.getComponentTypeList().subscribe(res => {
      this.componentTypeList = res;
      // console.log(res);
    });
  }

  compTypeOnchange (event: any) {
    // this.ss1 = event.target.value;
    this.getComponentName(event.target.value);
    this.selectedComponent_Type = event.target.value;
    this.selectedComponent_Type1 = event.target.value;
  }

  compNameOnchange(event: any) {
    this.selectedComponent_Name = event.target.value;
    this.selectedComponent_Name1 = event.target.value;
  }
  onSubmit() {
    // alert("test");
    // alert("type:" + this.selectedComponent_Type + "Name: " + this.selectedComponent_Name);
    // console.log('submit: name:', this.selectedComponent_Name1.replace('+', '%2B'), 'submit: type:',
      // this.selectedComponent_Type1.replace('+', '%2B'));
    if (this.selectedComponent_Name1 === '' || this.selectedComponent_Type1 === '') {
      this.hierarchialGraph = {nodes: [], links: [], label: [] };
    } else {
      if(this.selectedComponent_Name1.indexOf('&')!=-1) {
        this.selectedComponent_Name1 = this.selectedComponent_Name1.replace('&','$');
      }
      if(this.selectedComponent_Name1.indexOf('&&')!=-1) {
        this.selectedComponent_Name1 = this.selectedComponent_Name1.replace('&&','$$');
      }
      this.dataservice.getSpiderFlow(this.selectedComponent_Name1.replace('+', '%2B'),
      this.selectedComponent_Type1.replace('+', '%2B')).subscribe(res => {
        if (res.nodes.length !== 0) {
          (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'visible';
          (document.getElementById('spiderErrMsg') as HTMLInputElement).style.visibility = 'hidden';
          (document.getElementById('spiderDiag') as HTMLInputElement).style.visibility = 'visible';
          // console.log(Object.keys(res['links']).length);
          // console.log(res);
          this.hierarchialGraph = res;
          // console.log(res);
          // if ((Object.keys(res['links']).length) === 1) {
          //   alert('No graph found for the specified component name & type');
          // }
          //  if (Object.keys(res['links']).length > 1) {
          //     this.hierarchialGraph = res;
          //   } else {
          //     this.hierarchialGraph = res;
          // }
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

   //  let _str = data.name;
     const _str = data.name.split(' (');
     this.selectedComponent_Name = _str[0].trim(); // res1[0];
     this.selectedComponent_Type = _str[1].replace(')', '').trim();
    // console.log('click: name:', this.selectedComponent_Name, 'click:', this.selectedComponent_Type);
}
printData() {
  console.log('called');
  window.print();
  // const node = document.getElementById('spiderDiag');
  //   domtoimage.toPng(node).then(function (dataUrl) {
  //      const img = new Image();
  //       img.src = dataUrl;
  //       const link = document.createElement('a');
  //       link.setAttribute('href', img.src);
  //       link.setAttribute('download', (document.getElementById('cmpName') as HTMLInputElement).value);
  //       // link.setAttribute('download', this.selectedComponent_Name1);
  //       link.click();

  //   }).catch(function (error) {
  //       console.error('oops, something went wrong!', error);
  //   });
}

// showGraph() {
//   this.hierarchialGraph.nodes = [
//     {
//       id: 'first',
//       label: 'A'
//     }, {
//       id: 'second',
//       label: 'B'
//     }, {
//       id: 'c1',
//       label: 'C1'
//     }, {
//       id: 'c2',
//       label: 'C2'
//     }
// ];

// this.hierarchialGraph.links = [
//   {
//     id: 'a',
//     source: 'first',
//     target: 'second',
//     label: 'is parent of'
//   }, {
//     id: 'b',
//     source: 'first',
//     target: 'c1',
//     label: 'custom label'
//   }, {
//     id: 'c',
//     source: 'first',
//     target: 'c1',
//     label: 'custom label'
//   }, {
//     id: 'd',
//     source: 'first',
//     target: 'c2',
//     label: 'custom label'
//   }
// ];
// }
}
