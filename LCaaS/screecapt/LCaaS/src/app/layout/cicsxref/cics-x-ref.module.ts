import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { CICSXrefRoutingModule } from './cics-x-ref-routing.module';
import { CICSXrefComponent } from './cics-x-ref.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, CICSXrefRoutingModule, PageHeaderModule, DataTablesModule, NgbModule],
    declarations: [CICSXrefComponent]
})
export class CICSXrefModule {}
