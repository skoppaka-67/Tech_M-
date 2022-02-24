import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { CicsScreenRoutingModule } from './cicsscreen-routing.module';
import { CicsScreenComponent } from './cicsscreen.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, CicsScreenRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [CicsScreenComponent],
    providers: [ExcelService]
})
export class CicsScreenModule {}
