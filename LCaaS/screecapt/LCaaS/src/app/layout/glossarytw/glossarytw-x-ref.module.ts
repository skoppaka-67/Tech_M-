import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { GlosssaryTWXrefRoutingModule } from './glossarytw-x-ref-routing.module';
import { GlossaryTWXrefComponent } from './glossarytw-x-ref.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, GlosssaryTWXrefRoutingModule, PageHeaderModule, DataTablesModule, NgbModule],
    declarations: [GlossaryTWXrefComponent]
})
export class GlosssaryTWXrefModule {}
