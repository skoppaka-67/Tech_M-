import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { DataService } from '../layout/data.service';
import { TranslateService } from '@ngx-translate/core';
import { routerTransition } from '../router.animations';
// import {ExcelService} from '../excel.service';

@Component({
    selector: 'app-login',
    templateUrl: './login.component.html',
    styleUrls: ['./login.component.scss'],
    animations: [routerTransition()]
})
export class LoginComponent implements OnInit {
    name = '';
    password = '';
    status = '';
    OverAllUploadStatusds: any;
    OverAllUploadStatus_flag: any;
    public resultStatus: string;
    constructor(public dataservice: DataService, public router: Router) {

    }

    ngOnInit() {
      // this.getOverallUploadStatus();
      // this.setSessionStorage();
      console.clear();
    }

    getOverallUploadStatus() {
      this.dataservice.getOverallUploadStatus().subscribe(res => {
        this.OverAllUploadStatusds = res;
      //  this.OverAllUploadStatus_flag[3] = this.OverAllUploadStatusds.overall_status;
        // this.pieChartData[1] = this.pieChartDs.technical_debt.total_active_loc;
       // this.OverAllUploadStatus_flag[0] = this.OverAllUploadStatus.cross_ref_cobol;
        // this.doughnutChartData[1] = this.pieChartDs.orphan_stats.active_components;
        this.OverAllUploadStatus_flag = JSON.stringify(this.OverAllUploadStatusds);
        console.log('flag:' + this.OverAllUploadStatus_flag);
      }, error => {
        console.log(error);
      });
    }

    keyDownFunction(event) {
      if (event.keyCode === 13) {
        // console.log(event.keyCode);
        (document.getElementById('loginBtn') as HTMLInputElement).click();
      }
    }

    onLoggedin() {
        // this.getOverallUploadStatus();
        // status = this.OverAllUploadStatus_flag;
        this.name = (document.getElementById('Uname') as HTMLInputElement).value;
        this.password = (document.getElementById('Upwd') as HTMLInputElement).value;
        // validateUser
        // this.dataservice.validateUser(this.name, this.password).subscribe(res => {
        //   if (this.name === '' && this.password === '') {
        //     (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'visible';
        //     (document.getElementById('incorrectCreds') as HTMLInputElement).style.color = 'red';
        //     (document.getElementById('incorrectCreds') as HTMLInputElement).innerText = 'Please Enter User ID & Password';
        //   } else if (this.name === '') {
        //       (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'visible';
        //       (document.getElementById('incorrectCreds') as HTMLInputElement).style.color = 'red';
        //       (document.getElementById('incorrectCreds') as HTMLInputElement).innerText = 'Please Enter User ID';
        //   } else if (this.password === '') {
        //       (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'visible';
        //       (document.getElementById('incorrectCreds') as HTMLInputElement).style.color = 'red';
        //       (document.getElementById('incorrectCreds') as HTMLInputElement).innerText = 'Please Enter Password';
        //   } else if (this.name.length > 1 && this.password.length > 1) {
        //     if (res.validUser === 'true') {
        //       (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'hidden';
        //       localStorage.setItem('isLoggedin', 'true');
        //       sessionStorage.setItem('resultStatus', 'DATAAVAILABLE'); // web service data flag
        //       this.router.navigate(['/dashboard']);
        //       sessionStorage.setItem('id', this.name);
        //    } else if (res.validUser === 'false') {
        //         (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'visible';
        //         (document.getElementById('incorrectCreds') as HTMLInputElement).style.color = 'red';
        //         (document.getElementById('incorrectCreds') as HTMLInputElement).innerText = 'Incorrect Password';
        //     } else {
        //         (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'visible';
        //         (document.getElementById('incorrectCreds') as HTMLInputElement).style.color = 'red';
        //         (document.getElementById('incorrectCreds') as HTMLInputElement).innerText = 'User doesn\'t exist, Please contact admin.';
        //     }
        //   }
        //   }, error => {
        //   console.log(error);
        // });
        // if (this.name === 'UPRRADMIN' && this.password === 'UPRRPASS') {
        if (this.name === 'admin' && this.password === 'admin1') {
          (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'hidden';
           localStorage.setItem('isLoggedin', 'true');
          //  if (this.OverAllUploadStatus_flag == "true")
          //   {
                // console.log("1" + status);
                sessionStorage.setItem('resultStatus', 'DATAAVAILABLE'); // web service data flag
                this.router.navigate(['/dashboard']);
                sessionStorage.setItem('id', 'admin');
            // }
            // else
            // {
            //    // console.log("2" + status);
            //    sessionStorage.setItem('resultStatus','DATAAVAILABLE'); // web service data flag
            //     this.router.navigate(['/progress']);
            // }
        // }
        // else
        // {
        // }
        // } else if (this.name === 'geuser' && this.password === 'geuser1') {
        //   (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'hidden';
        //    localStorage.setItem('isLoggedin', 'true');
        //         sessionStorage.setItem('resultStatus', 'DATAAVAILABLE'); // web service data flag
        //         this.router.navigate(['/dashboard']);
        //         sessionStorage.setItem('id', 'geuser');
        //         // const userLoggedIn = sessionStorage.getItem('id');
        //         // if (userLoggedIn === 'lcaasadmin') {
        //         //   (document.getElementById('datamodelrouterlink') as HTMLInputElement).style.display = 'none';
        //         // }
        //         // hide nav bar here
        //         // working but..
        //         // console.log('data model hide');
        //         // setTimeout(() => {
        //         //   (document.getElementById('datamodelrouterlink') as HTMLInputElement).style.display = 'none';
        //         // }, 1100);

        } else if (this.name === 'lcaasadmin' && this.password === 'lcaasadmin1') {
          (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'hidden';
           localStorage.setItem('isLoggedin', 'true');
                sessionStorage.setItem('resultStatus', 'DATAAVAILABLE'); // web service data flag
                this.router.navigate(['/dashboard']);
                sessionStorage.setItem('id', 'lcaasadmin');
        } else if (this.name === 'demouser' && this.password === 'demouser1') {
          (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'hidden';
           localStorage.setItem('isLoggedin', 'true');
                sessionStorage.setItem('resultStatus', 'DATAAVAILABLE'); // web service data flag
                this.router.navigate(['/dashboard']);
                sessionStorage.setItem('id', 'demouser');
        } else if (this.name === 'geuser' && this.password === 'geuser1') {
          (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'hidden';
           localStorage.setItem('isLoggedin', 'true');
                sessionStorage.setItem('resultStatus', 'DATAAVAILABLE'); // web service data flag
                this.router.navigate(['/dashboard']);
                sessionStorage.setItem('id', 'geuser');
        } else if (this.name === '' && this.password === '') {
        (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'visible';
        (document.getElementById('incorrectCreds') as HTMLInputElement).style.color = 'red';
        (document.getElementById('incorrectCreds') as HTMLInputElement).innerText = 'Please Enter User ID & Password';
        } else if (this.name === '') {
          (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'visible';
          (document.getElementById('incorrectCreds') as HTMLInputElement).style.color = 'red';
          (document.getElementById('incorrectCreds') as HTMLInputElement).innerText = 'Please Enter User ID';
        } else if (this.password === '') {
          (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'visible';
          (document.getElementById('incorrectCreds') as HTMLInputElement).style.color = 'red';
          (document.getElementById('incorrectCreds') as HTMLInputElement).innerText = 'Please Enter Password';
        } else {
        (document.getElementById('incorrectCreds') as HTMLInputElement).style.visibility = 'visible';
        (document.getElementById('incorrectCreds') as HTMLInputElement).style.color = 'red';
        (document.getElementById('incorrectCreds') as HTMLInputElement).innerText = 'Incorrect User ID or Password';
    }
  }
}

