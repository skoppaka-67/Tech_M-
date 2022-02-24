import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import * as shape from 'd3-shape';
import { DataService } from '../data.service';
import { Directive, HostListener } from '@angular/core';
import { Edge, Node, ClusterNode, Layout } from '@swimlane/ngx-graph';
import {PrintService} from '../../print.service';
import * as domtoimage from 'dom-to-image';
import * as inputJson from '../input.json';

@Component({
    selector: 'app-callchainapp',
    templateUrl: './callchain-application.component.html',
    styleUrls: ['./callchain-application.component.scss'],
    animations: [routerTransition()]
})
export class CallChainAppComponent implements OnInit {

  constructor(public dataservice: DataService, public printService: PrintService ) {}

  title = 'Spider Chart';
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
  applicationTypeList: any[] = [];
  selectedApplication='';

  ngOnInit(): void {
    window.scrollTo(0, 0);
    // this.getAppList();
    (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'hidden';
    // this.getComponentTypeList();
    this.getLoadedValues();
  }
  getLoadedValues() {
    // console.log(inputJson[0], inputJson[0].appName);
    if ( inputJson[0].appName !== undefined && inputJson[0].appName !== '') {
      this.getAppList();
      setTimeout(() => {
        // (document.getElementById('appln') as HTMLInputElement).value = inputJson[0].appName;
        // this.selectedApplication = inputJson[0].appName;
        // this.getComponentTypeListWithApp(inputJson[0].appName);
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
          this.getComponentTypeListWithApp(inputJson[0].appName);
        }
        else {
          var mySelect = document.getElementById('appln') as HTMLSelectElement;
          mySelect.selectedIndex = 1;
          this.selectedApplication = (document.getElementById('appln') as HTMLInputElement).value;
          // document.getElementById('submitBtn').click();
          this.getComponentTypeListWithApp((document.getElementById('appln') as HTMLInputElement).value);
        }
        setTimeout(() => {
          (document.getElementById('cmp') as HTMLInputElement).value = inputJson[0].compType;
          this.selectedComponent_Type = inputJson[0].compType;
          this.getComponentNameWithApp(inputJson[0].compType);
          setTimeout(() => {
            // (document.getElementById('cmpName') as HTMLInputElement).value = inputJson[0].compName;
            // this.selectedComponent_Name = inputJson[0].compName;

            var flag = false;
            var selectedTrends = document.getElementById('cmpName') as HTMLSelectElement;
            for(var i=0; i < selectedTrends.length; i++)
            {
              if(selectedTrends.options[i].value == inputJson[0].compName ){
                  flag=true;
                  break;
                }
            }
            if (flag){
              (document.getElementById('cmpName') as HTMLInputElement).value = inputJson[0].compName
              this.selectedComponent_Name = inputJson[0].compName;
            }
            else {
              var mySelect = document.getElementById('cmpName') as HTMLSelectElement;
              mySelect.selectedIndex = 1;
              this.selectedComponent_Name = (document.getElementById('cmpName') as HTMLInputElement).value;
            }

            setTimeout(() => {
              (document.getElementById('filter') as HTMLInputElement).value = "child";
              this.selectedLevel = "child";
              setTimeout(() => {
                document.getElementById('submitBtn').click();
              }, 500);
            }, 500);
          }, 500);
        }, 500);
      }, 500);
    } else {
      this.getAppList();
    }
  }
  getAppList() {
    this.dataservice.getAppList().subscribe(res => {
      this.applicationTypeList = res.application_list;
      console.clear();
  });
  }
  applicationTypeOnchange(event: any) {
    this.selectedApplication = event.target.value;
    inputJson[0].appName = event.target.value;
    this.getComponentTypeListWithApp(event.target.value);
    this.selectedComponent_Type = '';
    (document.getElementById('cmp') as HTMLInputElement).value = '';

  }
  getComponentName(comp_type) {
    this.dataservice.getComponentName(comp_type).subscribe(res => {
      this.componentList = res;
    });
  }
  getComponentTypeListWithApp(appName) {
    this.dataservice.getComponentTypeListWithApp(appName).subscribe(res => {
      this.componentTypeList = res;
    });
  }
  compTypeOnchange (event: any) {
    this.getComponentNameWithApp(event.target.value);
    inputJson[0].compType = event.target.value;
    this.selectedComponent_Type = event.target.value;
    this.selectedComponent_Name = '';
    (document.getElementById('cmpName') as HTMLInputElement).value = '';

  }
  getComponentNameWithApp(compType) {
    if (this.selectedApplication.indexOf('&') != -1) {
      this.selectedApplication = this.selectedApplication.replace('&', '$');
    }
    this.dataservice.getComponentNameWithApp(compType, this.selectedApplication).subscribe(res => {
      this.componentList = res;
    });
  }

  // getComponentTypeList() {
  //   this.dataservice.getComponentTypeList().subscribe(res => {
  //     this.componentTypeList = res;
  //   });
  // }

  // compTypeOnchange (event: any) {
  //   this.getComponentName(event.target.value);
  //   this.selectedComponent_Type = event.target.value;
  // }
  levelOnchange(event: any) {
    this.selectedLevel = event.target.value;
    inputJson[0].callChainLevel = "child";
  }

  compNameOnchange(event: any) {
    this.selectedComponent_Name = event.target.value;
    inputJson[0].compName = event.target.value;
    this.selectedLevel = '';
    (document.getElementById('filter') as HTMLInputElement).value = '';
  }
  onSubmit() {
    if (this.selectedComponent_Name === '' || this.selectedComponent_Type === '' || this.selectedLevel === '') {
      this.hierarchialGraph = {nodes: [], links: [], label: [] };
      (document.getElementById('spiderErrMsg') as HTMLInputElement).style.visibility = 'visible';
      (document.getElementById('spiderErrMsg') as HTMLInputElement).style.color = 'red';
      (document.getElementById('spiderErrMsg') as HTMLInputElement).innerHTML = 'Please select all values';
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
      this.dataservice.getNaturalSpiderFlow(this.selectedComponent_Name.replace('+', '%2B'),
      this.selectedComponent_Type.replace('+', '%2B'), this.selectedLevel).subscribe(res => {
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
