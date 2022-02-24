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
    selector: 'app-spiderfilterapp',
    templateUrl: './spiderfilter-application.component.html',
    styleUrls: ['./spiderfilter-application.component.scss'],
    animations: [routerTransition()]
})
export class SpiderFilterAppComponent implements OnInit {

  constructor(public dataservice: DataService, public printService: PrintService ) {}

  title = 'Spider Chart';
  hierarchialGraph = { nodes: [], links: [], label: [] };
  curve = shape.curveBundle.beta(1);
  layout: String = 'colaForceDirected';
  componentList: any[] = [];
  componentTypeList: any[] = [];
  filterList: any[] = [];
  selectedComponent_Name = '';
  selectedComponent_Type = '';
  selectedComponent_Name1 = '';
  selectedComponent_Type1 = '';
  selectedFilter = '';
  selectedFilter1 = '';
  comp_type = '';
  applicationTypeList: any[] = [];
  selectedApplication = '';
  view = [5000, 2000];

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
        // console.log('getcomTypCalled');
        setTimeout(() => {
          (document.getElementById('cmp') as HTMLInputElement).value = inputJson[0].compType;
          this.selectedComponent_Type = inputJson[0].compType;
          this.selectedComponent_Type1 = inputJson[0].compType;
          this.getComponentNameWithApp(inputJson[0].compType);
          console.log('getcomNameCalled');
          setTimeout(() => {
            // (document.getElementById('cmpName') as HTMLInputElement).value = inputJson[0].compName;
            // this.selectedComponent_Name = inputJson[0].compName;
            // this.selectedComponent_Name1 = inputJson[0].compName;
            // this.populateFilterDropdown(inputJson[0].compName);
            console.log('getFilterCalled');

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
              // this.selectedApplication = inputJson[0].compName;
              // document.getElementById('submitBtn').click();
              this.selectedComponent_Name = inputJson[0].compName;
              this.selectedComponent_Name1 = inputJson[0].compName;
              this.populateFilterDropdown(inputJson[0].compName);
            }
            else {
              var mySelect = document.getElementById('cmpName') as HTMLSelectElement;
              mySelect.selectedIndex = 1;
              // this.selectedApplication = (document.getElementById('cmpName') as HTMLInputElement).value;
              // document.getElementById('submitBtn').click();
              this.selectedComponent_Name = (document.getElementById('cmpName') as HTMLInputElement).value;
              this.selectedComponent_Name1 = (document.getElementById('cmpName') as HTMLInputElement).value;
              this.populateFilterDropdown((document.getElementById('cmpName') as HTMLInputElement).value);
            }

            setTimeout(() => {
              (document.getElementById('filter') as HTMLInputElement).value = inputJson[0].spiderFilter;
              this.selectedFilter = inputJson[0].spiderFilter;
              this.selectedFilter1 = inputJson[0].spiderFilter;
              setTimeout(() => {
                document.getElementById('submitBtn').click();
                console.log('buttnClicked');
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
      // console.clear();
  });
  }
  applicationTypeOnchange(event: any) {
    this.selectedApplication = event.target.value;
    inputJson[0].appName = event.target.value;
    this.selectedComponent_Type = '';
    this.selectedComponent_Type1 = '';
    (document.getElementById('cmp') as HTMLInputElement).value = '';
    this.getComponentTypeListWithApp(event.target.value);
  }
  getComponentTypeListWithApp(appName) {
    this.dataservice.getComponentTypeListWithApp(appName).subscribe(res => {
      this.componentTypeList = res;
    });
  }
  compTypeOnchange (event: any) {
    this.getComponentNameWithApp(event.target.value);
    this.selectedComponent_Type = event.target.value;
    this.selectedComponent_Type1 = event.target.value;
    inputJson[0].compType = event.target.value;
    this.selectedComponent_Name = '';
    this.selectedComponent_Name1 = '';
    (document.getElementById('cmpName') as HTMLInputElement).value = '';
  }
  getComponentNameWithApp(compType) {
    if (this.selectedApplication.indexOf('&') != -1) {
      this.selectedApplication = this.selectedApplication.replace('&','$');
    }
    this.dataservice.getComponentNameWithApp(compType, this.selectedApplication).subscribe(res => {
      this.componentList = res;
    });
  }
  compNameOnchange(event: any) {
    this.populateFilterDropdown(event.target.value);
    inputJson[0].compName = event.target.value;
    this.selectedFilter = '';
    (document.getElementById('filter') as HTMLInputElement).value = '';
    this.selectedComponent_Name = event.target.value;
    this.selectedComponent_Name1 = event.target.value;
  }
  @HostListener('dblclick') onDoubleClicked() {
    if (this.selectedComponent_Name === '' || this.selectedComponent_Type === '') {
      this.hierarchialGraph = {nodes: [], links: [], label: [] };
    } else {
      this.dataservice.getSpiderFilterFlow(this.selectedComponent_Name.replace('+', '%2B'),
      this.selectedComponent_Type.replace('+', '%2B'), this.selectedFilter).subscribe(res => {
        this.hierarchialGraph = res;
      });
    }
  }
  /*getComponentName(comp_type) {
    this.dataservice.getComponentName(comp_type).subscribe(res => {
      this.componentList = res;
      // console.log(this.componentList);
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
    this.selectedComponent_Type1 = event.target.value;
  }
  compNameOnchange(event: any) {
    this.populateFilterDropdown(event.target.value);
    this.selectedFilter = '';
    this.selectedComponent_Name = event.target.value;
    this.selectedComponent_Name1 = event.target.value;

  }*/
  populateFilterDropdown(selectedName) {
    if (selectedName === '' || this.selectedComponent_Type1 === '') {
    } else {
      if (selectedName.indexOf('#') != -1) {
        selectedName = selectedName.replace('#', 'HASH');
      }
      if(selectedName.indexOf('&') != -1) {
        selectedName = selectedName.replace('&', '$');
      }
      if(selectedName.indexOf('&&') != -1) {
        selectedName = selectedName.replace('&&', '$$');
      }
      this.dataservice.getSpiderFilterList(selectedName.replace('+', '%2B'),
        this.selectedComponent_Type1.replace('+', '%2B')).subscribe(res => {
          // for(var i=0; i<res.unique_name_type_map.length; i++){
          //   this.filterList.push(res.unique_name_type_map[i]);
          // }
          this.filterList = res;
          console.log(res);
      });
    }
  }
  filterOnchange(event: any) {
    this.selectedFilter = event.target.value;
    this.selectedFilter1 = event.target.value;
    inputJson[0].spiderFilter = event.target.value;
  }
  onSubmit() {
    if (this.selectedComponent_Name1 === '' || this.selectedComponent_Type1 === '' || this.selectedFilter1 === '') {
      this.hierarchialGraph = {nodes: [], links: [], label: [] };
    } else {
      if(this.selectedComponent_Name1.indexOf('#')!=-1) {
        this.selectedComponent_Name1 = this.selectedComponent_Name1.replace('#','HASH');
      }
      if(this.selectedComponent_Name1.indexOf('&')!=-1) {
        this.selectedComponent_Name1 = this.selectedComponent_Name1.replace('&','$');
      }
      if(this.selectedComponent_Name1.indexOf('&&')!=-1) {
        this.selectedComponent_Name1 = this.selectedComponent_Name1.replace('&&','$$');
      }
      this.dataservice.getSpiderFilterFlow(this.selectedComponent_Name1.replace('+', '%2B'),
      this.selectedComponent_Type1.replace('+', '%2B'), this.selectedFilter1).subscribe(res => {
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
