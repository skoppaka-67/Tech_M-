import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { GlosssaryXrefRoutingModule } from './glossary-x-ref-routing.module';
import { GlossaryXrefComponent } from './glossary-x-ref.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, GlosssaryXrefRoutingModule, PageHeaderModule, DataTablesModule, NgbModule],
    declarations: [GlossaryXrefComponent]
})
export class GlosssaryXrefModule {}
