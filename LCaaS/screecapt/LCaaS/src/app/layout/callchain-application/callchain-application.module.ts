// import { NgModule } from '@angular/core';
import { NgModule, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import {DataTablesModule } from 'angular-datatables';
import { SpiderAppRoutingModule } from './callchain-application-routing.module';
import { CallChainAppComponent } from './callchain-application.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';


@NgModule({
    imports: [CommonModule, SpiderAppRoutingModule, PageHeaderModule, DataTablesModule, NgxGraphModule, NgxChartsModule],
    declarations: [CallChainAppComponent],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [ExcelService],
    bootstrap:    [CallChainAppComponent]
})
export class CallChainAppModule {}
