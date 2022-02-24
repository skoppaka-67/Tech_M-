import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { Subject } from 'rxjs';
import { DataTableDirective } from 'angular-datatables';
import {ExcelService} from '../../excel.service';
import { HttpClient } from '@angular/common/http';
import { NgProgress } from '@ngx-progressbar/core';




@Component({
    selector: 'app-progress',
    templateUrl: './progress.component.html',
    styleUrls: ['./progress.component.scss'],
    animations: [routerTransition()]
})
export class ProgressComponent implements OnInit {
    title = 'app';
    //statuslist:any[]=[];
    statuslist:any=[];
    s3Path:string="";
    temp:string;
    options = {
      minimum: 0.08,
      maximum: 1,
      ease: 'linear',
      speed: 200,
      trickleSpeed: 300,
      meteor: true,
      spinner: true,
      spinnerPosition: 'right',
      direction: 'leftToRightIncreased',
      color: 'red',
      thick: true
    };
    startedClass = false;
    endedClass = false;
    preventAbuse = false;
    completedClass = false;

    constructor(public dataservice:DataService, public progress: NgProgress, private http: HttpClient) {}
    
    ngOnInit(){

      this.progress.started.subscribe(() => {

        this.startedClass = true;
        setTimeout(() => {
          this.startedClass = false;
        }, 800);
      });
  
      this.progress.ended.subscribe(() => {
  
        this.endedClass = true;
        setTimeout(() => {
          this.endedClass = false;
        }, 10000);
      });
              
      //console.log(this.dataSets);
    }
    onStarted() {
      this.startedClass = true;
      setTimeout(() => {
        this.startedClass = false;
      }, 800);
    }
  
    onCompleted() {
      this.completedClass = true;
      setTimeout(() => {
        this.completedClass = false;
      }, 800);
    }
    testHttp() {
      this.preventAbuse = true;
      this.http.get('https://jsonplaceholder.typicode.com/posts/1').subscribe(res => {
        console.log(res);
        setTimeout(() => {
          this.preventAbuse = false;
        }, 10000);
      });
    }
    onSubmit(){
      this.preventAbuse = true;
      this.dataservice.GetProgressStatus(this.s3Path).subscribe(res=>{
        this.statuslist=res;
      //  console.log(this.statuslist);
        this.temp = JSON.stringify(this.statuslist);
        //this.showLoader = false;
       // console.log(this.temp);
       setTimeout(() => {
        this.preventAbuse = false;
      }, 1000);
    });
  }    
    
}
