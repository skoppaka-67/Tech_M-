import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.scss'],
  animations: [routerTransition()]
})
export class RegisterComponent implements OnInit {

  constructor(public dataservice: DataService) { }
  role = '';
  userRoles: any[] = [];
  ngOnInit() {
  }
  // onChange(role: string) {
  //   if (role === '') {
  //       this.role = '';
  //   } else {
  //       this.role = role;
  //   }
  // }
  // getUserRoleList() {
  //   // this.dataservice.getUserRole().subscribe(res => {
  //   //     this.userRoles = res.roleList;
  //   // });
  // }
  // download a file from HTTP call.
  // downloadTemplateDocument(){
  //   this.dataservice.dwnTemplateDocument().subscribe(resp => resp.blob().then(blob => {
  //     const url = window.URL.createObjectURL(blob);
  //     const a = document.createElement('a');
  //     a.style.display = 'none';
  //     a.href = url;
  //     a.download = 'Template-document';
  //     document.body.appendChild(a);
  //     a.click();
  //     window.URL.revokeObjectURL(url);
  //   }));
  // }
  // insertValueToDB(userID, pwd) {
  //   this.dataservice.userExists(userID).subscribe(resp => {
  //     if (resp.userExists === 'true') {
  //       (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'red';
  //       (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'User ID already exists';
  //     } else {
  //       this.dataservice.createUser(userID, pwd).subscribe(res => {
  //         if (res.userCreateStatus === 'success') {
  //           (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'green';
  //           (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'User Successfully created';
  //         }
  //         }, error => {
  //         console.log(error);
  //       });
  //     }
  //     }, error => {
  //     console.log(error);
  //   });
  // }
  // onSubmit() {
  //   const name = (document.getElementById('fullName') as HTMLInputElement).value;
  //   const userID = (document.getElementById('userId') as HTMLInputElement).value;
  //   const pwd = (document.getElementById('password') as HTMLInputElement).value;
  //   const repeatPwd = (document.getElementById('repeatPassword') as HTMLInputElement).value;
  //   if (name === '') {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'red';
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'Please enter Name';
  //   } else if (userID === '') {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'red';
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'Please enter ID';
  //   } else if (pwd === '') {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'red';
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'Please enter password';
  //   } else if (repeatPwd === '') {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'red';
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'Please re-enter password';
  //   } else if (name !== '' && userID !== '' && pwd !== '' && repeatPwd !== '' && pwd === repeatPwd && pwd.length >= 6) {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = '';
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).style.display = 'hidden';
  //     this.insertValueToDB(userID, pwd);
  //   }
  //   if (pwd !== repeatPwd) {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'red';
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'Passwords don\'t match';
  //   }
  //   if (pwd.length < 6) {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'red';
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'Please enter atleast 6 characters';
  //   }
  // }
  // resetFields() {
  //   (document.getElementById('fullName') as HTMLInputElement).value = '';
  //   (document.getElementById('userId') as HTMLInputElement).value = '';
  //   (document.getElementById('password') as HTMLInputElement).value = '';
  //   (document.getElementById('repeatPassword') as HTMLInputElement).value = '';
  //   (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = '';
  // }
  // checkLength(el) {
  //   if (el.length < 6) {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'red';
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'Please enter atleast 6 characters';
  //   } else {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = '';
  //   }
  // }
  // checkPwdMatch(el) {
  //   if (el !== (document.getElementById('password') as HTMLInputElement).value) {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'red';
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'Passwords don\'t match';
  //   } else if (el.length < 6) {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).style.color = 'red';
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = 'Please enter atleast 6 characters';
  //   } else {
  //     (document.getElementById('formErrorMsg') as HTMLInputElement).innerHTML = '';
  //   }
  // }
}
