// import { NgModule } from '@angular/core';
import { NgModule, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';

import { CommonModule } from '@angular/common';


import {DataTablesModule } from 'angular-datatables';

import { BrePlSqlRoutingModule } from './breplsql-routing.module';
import { BrePlSqlComponent } from './breplsql.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';

import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';



@NgModule({
    imports: [CommonModule, BrePlSqlRoutingModule, PageHeaderModule, DataTablesModule, NgxGraphModule, NgxChartsModule,
        NgbModule],
    declarations: [BrePlSqlComponent],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [ExcelService],
    bootstrap:    [BrePlSqlComponent]
})
export class BrePlSqlModule {}
