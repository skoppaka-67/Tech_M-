import { Component, OnInit, Input } from '@angular/core';
import { routerTransition } from '../../router.animations';
import 'zone.js/dist/zone';
import { DataService } from '../data.service';


@Component({
    selector: 'app-techspec',
    templateUrl: './techspec.component.html',
    styleUrls: ['./techspec.component.scss'],
    animations: [routerTransition()]
})

export class TechSpecComponent implements OnInit {

    @Input() name: string;
    constructor(public dataservice: DataService) {}
    ip = this.dataservice.ip;
    port = this.dataservice.port;
    pdfSrcDomain;
    // pdfSrcDomain = 'http://172.18.32.128:7999/'
    pdfSrcLoc = 'assets/pdf/';
    pdfSrc;
    applicationTypeList;
    selectedApplication;
    programNameList;
    selectedComponent;

    ngOnInit() {
      window.scrollTo(0, 0);
      this.applicationList();
      // this.pdfSrcDomain = 'http://' + this.ip + ':8080' + '/ProdTechDoc/';
      this.pdfSrcDomain = 'http://' + this.ip + ':' + this.port + '/';
      (document.getElementById('downloadBtn') as HTMLElement).style.visibility = 'visible'; //changed
      // (document.getElementById('generateBtn') as HTMLElement).style.visibility = 'visible';
      // this.pdfSrc = "assets/pdf/LCaaS_User_Guide.pdf";
    }
    openPdf() {
      console.log(this.pdfSrcDomain + this.pdfSrcLoc + this.selectedComponent +'.docx');
      window.open(this.pdfSrcDomain + this.pdfSrcLoc + this.selectedComponent +'.docx');
    }
    
    applicationList() {
      this.dataservice.getApplicationList().subscribe(res => {
        this.applicationTypeList = res.application_list;
      });
    }
    applicationTypeOnchange(event: any){
      this.getProgramNameList(event.target.value);
      this.selectedApplication = event.target.value;
    }
    onGenerate(){
     /* this.dataservice.generateDocument(this.selectedComponent).subscribe(res => {
        if(res.status === 'success') {
          (document.getElementById('downloadBtn') as HTMLElement).style.visibility = 'visible';
          (document.getElementById('errMsg') as HTMLElement).style.visibility = 'hidden';
        } else if(res.status === 'failure'){
          (document.getElementById('downloadBtn') as HTMLElement).style.visibility = 'hidden';
          (document.getElementById('errMsg') as HTMLElement).style.visibility = 'visible';
          (document.getElementById('errMsg') as HTMLElement).style.color = 'red';
          (document.getElementById('errMsg') as HTMLInputElement).innerHTML = 'Error generating document.';
           
        }
      });*/
    }
    // onSubmit(){
    //   this.pdfSrc = this.pdfSrcLoc + this.selectedComponent +'.pdf';
    // }
    getProgramNameList(selectedApplication){
      this.dataservice.getProgramNameList(selectedApplication).subscribe(res => {
        if(res.component_list){
        var tempList = [];
        for(var x of res.component_list){
          tempList.push(x.split('.')[0])
         }
        this.programNameList = tempList;
      }
    });
    }
    programNameOnchange(event: any){
      this.selectedComponent = event.target.value;
      if(this.selectedComponent === ''){
        (document.getElementById('downloadBtn') as HTMLElement).style.visibility = 'hidden';
        // (document.getElementById('generateBtn') as HTMLElement).style.visibility = 'hidden';

      } else {
        (document.getElementById('downloadBtn') as HTMLElement).style.visibility = 'visible';
        // (document.getElementById('generateBtn') as HTMLElement).style.visibility = 'visible';
      }
    }
}

