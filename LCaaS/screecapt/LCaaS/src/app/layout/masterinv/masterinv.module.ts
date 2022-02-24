import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { MasterinvRoutingModule } from './masterinv-routing.module';
import { MasterinvComponent } from './masterinv.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, MasterinvRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [MasterinvComponent],
    providers: [ExcelService]
})
export class MasterinvModule {}
