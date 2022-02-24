import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { DeadparaRoutingModule } from './deadpara-routing.module';
import { DeadparaComponent } from './deadpara.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';


@NgModule({
    imports: [CommonModule, DeadparaRoutingModule, PageHeaderModule,DataTablesModule, NgbModule], 
    declarations: [DeadparaComponent],
    providers: [ExcelService]
})
export class DeadparaModule {}
