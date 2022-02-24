import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { FormAppRoutingModule } from './form-application-routing.module';
import { FormAppComponent } from './form-application.component';
import { PageHeaderModule } from './../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';


@NgModule({
    imports: [CommonModule, FormAppRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [FormAppComponent]

})
export class FormAppModule {}
