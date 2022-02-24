import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { DatamodelRoutingModule } from './datamodel-routing.module';
import { DatamodelComponent } from './datamodel.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';


@NgModule({
    imports: [CommonModule, DatamodelRoutingModule, PageHeaderModule,DataTablesModule, NgbModule], 
    declarations: [DatamodelComponent],
    providers: [ExcelService]
})
export class DatamodelModule {}
