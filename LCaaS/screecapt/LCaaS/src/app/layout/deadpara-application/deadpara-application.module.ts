import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { DeadparaAppRoutingModule } from './deadpara-application-routing.module';
import { DeadparaAppComponent } from './deadpara-application.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';


@NgModule({
    imports: [CommonModule, DeadparaAppRoutingModule, PageHeaderModule,DataTablesModule, NgbModule], 
    declarations: [DeadparaAppComponent],
    providers: [ExcelService]
})
export class DeadparaAppModule {}
