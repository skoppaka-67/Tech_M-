// import { NgModule } from '@angular/core';
import { NgModule, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import {DataTablesModule } from 'angular-datatables';
import { SpiderFilterRoutingModule } from './spiderfilter-routing.module';
import { SpiderFilterComponent } from './spiderfilter.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';


@NgModule({
    imports: [CommonModule, SpiderFilterRoutingModule, PageHeaderModule, DataTablesModule, NgxGraphModule, NgxChartsModule],
    declarations: [SpiderFilterComponent],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [ExcelService],
    bootstrap:    [SpiderFilterComponent]
})
export class SpiderFilterModule {}
