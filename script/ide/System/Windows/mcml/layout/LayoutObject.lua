--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
local LayoutObject = commonlib.gettable("System.Windows.mcml.layout.LayoutObject");
LayoutObject:new():init();
------------------------------------------------------------
]]
local LayoutObject = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutObject"));

function LayoutObject:ctor()
	self.node = nil;
	self.style = nil;
	--self.control = nil;

	self.parent = nil;
	self.previous = nil;
	self.next= nil;

	--self.children = {};

	self.setNeedsLayoutForbidden = false;

	-- LayoutObject Bit fields holds all the boolean values for LayoutObject.
	self.needsLayout = false;
	self.needsPositionedMovementLayout = false;
	self.normalChildNeedsLayout = false;
	self.posChildNeedsLayout = false;
	self.needsSimplifiedNormalFlowLayout = false;
    self.preferredLogicalWidthsDirty = false;

	self.floating = false;

	self.positioned = false;
	self.relPositioned = false;

	self.isAnonymous = false;
	
	self.isText = false;
	self.isBox = false;
	self.inline = false;
	self.replaced= false;
	self.horizontalWritingMode = true;
	self.isDragging = false;

	self.hasOverflowClip = false;
	self.hasTransform = false;

	self.everHadLayout = false;

	self.childrenInline = false;

	self.marginBeforeQuirk = false;
	self.marginAfterQuirk = false;
	self.hasColumns = false;
	self.inRenderFlowThread = false;


--	self.needsUpdateCss = true;
--
--	self.bUseSpace = false;
end

function LayoutObject:init(node)
	self.node = node;
	--self.control = node:GetControl();
--	self.style = computed_style;
--	if(self.style) then
--		self.style:Connect("Changed", function()
--			self:invalidate();
--			--self.needsLayout = true;
--		end)
--	end
	return self;
end

-- 后面需要完善，暂时不调用该函数
function LayoutObject:CreateLayoutObject(node, style)
	local display = style:GetDisplay();
end

function LayoutObject:SetStyle(style)
	self.style = style;
	if(self.style) then
		self.style:Connect("Changed", function()
			self:invalidate();
			--self.needsLayout = true;
		end)
	end
end

function LayoutObject:GetControl()
	if(self.node) then
		return self.node:GetControl();
	end	
end

function LayoutObject:PreviousSibling()
	return self.previous;
end

function LayoutObject:NextSibling()
	return self.next;
end

function LayoutObject:SetPreviousSibling(previous)
	self.previous = previous;
--	if(previous) then
--		previous:SetNextSibling(self);
--	end
end

function LayoutObject:SetNextSibling(next)
	self.next = next;
end

function LayoutObject:SetParent(parent)
    self.parent = parent;
    if (parent and parent:InRenderFlowThread()) then
        self:SetInRenderFlowThread(true);
    elseif (not parent and self:InRenderFlowThread()) then
        self:SetInRenderFlowThread(false);
	end
end

function LayoutObject:AddChild(newChild, beforeChild)
--	if(next(self.children)) then
--		local previous = self.children[#self.children];
--		child:SetPreviousSibling(previous);
--	end
--	child.parent = self;
--	self.children[#self.children+1]=child;
--	child.index = #self.children;

	local children = self:VirtualChildren();
    if (not children) then
        return;
	end
    local beforeContent = 0;
    local beforeChildHasBeforeAndAfterContent = false;
    if (beforeChild and (beforeChild:IsTable() or beforeChild:IsTableSection() or beforeChild:IsTableRow() or beforeChild:IsTableCell())) then
--        beforeContent = beforeChild->findBeforeContentRenderer();
--        RenderObject* afterContent = beforeChild->findAfterContentRenderer();
--        if (beforeContent && afterContent) {
--            beforeChildHasBeforeAndAfterContent = true;
--            beforeContent->destroy();
--        }
    end

    local needsTable = false;

    if (newChild:IsTableCol() and newChild:Style():Display() == "TABLE_COLUMN_GROUP") then
        needsTable = not self:IsTable();
    elseif (newChild:IsLayoutBlock() and newChild:Style():Display() == "TABLE_CAPTION") then
        needsTable = not self:IsTable();
    elseif (newChild:IsTableSection()) then
        needsTable = not self:IsTable();
    elseif (newChild:IsTableRow()) then
        needsTable = not self:IsTableSection();
    elseif (newChild:IsTableCell()) then
        needsTable = not self:IsTableRow();
        -- I'm not 100% sure this is the best way to fix this, but without this
        -- change we recurse infinitely when trying to render the CSS2 test page:
        -- http://www.bath.ac.uk/%7Epy8ieh/internet/eviltests/htmlbodyheadrendering2.html.
        -- See Radar 2925291.
        if (needsTable and self:IsTableCell() and not children:FirstChild() and not newChild:IsTableCell()) then
            needsTable = false;
		end
    end

    if (needsTable) then
--        RenderTable* table;
--        RenderObject* afterChild = beforeChild ? beforeChild->previousSibling() : children->lastChild();
--        if (afterChild && afterChild->isAnonymous() && afterChild->isTable() && !afterChild->isBeforeContent())
--            table = toRenderTable(afterChild);
--        else {
--            table = new (renderArena()) RenderTable(document() /* is anonymous */);
--            RefPtr<RenderStyle> newStyle = RenderStyle::create();
--            newStyle->inheritFrom(style());
--            newStyle->setDisplay(TABLE);
--            table->setStyle(newStyle.release());
--            addChild(table, beforeChild);
--        }
--        table->addChild(newChild);
    else
        -- Just add it...
		children:InsertChildNode(self, newChild, beforeChild);
    end

--    if (newChild->isText() && newChild->style()->textTransform() == CAPITALIZE) {
--        RefPtr<StringImpl> textToTransform = toRenderText(newChild)->originalText();
--        if (textToTransform)
--            toRenderText(newChild)->setText(textToTransform.release(), true);
--    }
--
--    if (beforeChildHasBeforeAndAfterContent)
--        children->updateBeforeAfterContent(this, BEFORE);
end

function LayoutObject:AddChildIgnoringContinuation(newChild, beforeChild)
	return self:AddChild(newChild, beforeChild);
end

function LayoutObject:FirstChild()
	local children = self:VirtualChildren();
	if (children) then
        return children:FirstChild();
	end
    return nil;

--	if(next(self.children)) then
--		return self.children[1];
--	end
--	return;
end

function LayoutObject:LastChild()
	local children = self:VirtualChildren();
	if (children) then
        return children:LastChild();
	end
    return nil;
end

function LayoutObject:isHidden()
	return self.node:isHidden();
end

function LayoutObject:BeChanged()
	return self.style:BeChanged();
end

--function LayoutObject:CheckStyleChange()
--	if(not self:BeChanged()) then
--		return;
--	end
--
--	self:UpdateLayoutIfNeeded();
----	if(self:layoutChanged()) then
----		self:recalcLayout();
----	end
--
--	--self.node:up
--
--	self.style:ClearChanges();
--end

--function LayoutObject:fixedSize()
--	local style_item = self.style:GetStyle();
--	if(style_item.width and style_item.height) then
--		return true;
--	end
--	return false;
--end

--function LayoutObject:AncestorOf(layout)
--	
--end

--function LayoutObject:recalcLayout()
--	self.layout:SetUsedSize(0,0);
--	self.node:UpdateChildLayout(self.layout);
--end

--function LayoutObject:UpdateChildLayout(layout, child)
--	child:UpdateLayoutIfNeeded(layout);
--end

function LayoutObject:UpdateChildrenLayout(layout, beParentRelayout, beInDirtyRegion)
	local child = self:FirstChild();
	while(child) do
		child:UpdateLayout(layout, beParentRelayout, beInDirtyRegion);
		child = child:NextSibling();
	end
end

function LayoutObject:beUseSpace()
	if(self:Style():Position() == "static") then
		return true;
	end
	return false;
end

function LayoutObject:invalidate()
	if(self.needsLayout) then
		return;
	end
	--self.needsLayout = true;
	local page_layout = self:GetPageLayout();
	page_layout:invalidate(self);
end

function LayoutObject:BeLayoutView()
	return false;
end

---- TODO: 回溯父对象，添加相应布局标志
--function LayoutObject:markContainingBlocksForLayout()
--	if(not self:beUseSpace()) then
--		return;		
--	end
--	local parent = self:GetParent();
--	while(parent) do
--		parent.childrenNeedsLayout = true;
--		--parent.needsLayout = true;
--		if(parent:beFixedLayout()) then
--			--parent.childrenNeedsLayout = true;
--			parent.beSubtreeRoot = true;
--			break;
--		end
--		local next = parent:NextSibling();
--		while(next) do
--			next.needsPositionedMovementLayout = true;
--			next = next:NextSibling();
--		end
--		parent = parent:GetParent();
--	end
--end

function LayoutObject:ChangedBackTrace()
	local changeType = self:Style():Diff();
	if(changeType ~= "no_change") then
		self.needsLayout = true;
		self.normalChildNeedsLayout = true;
		self.posChildNeedsLayout = true;
		self:markContainingBlocksForLayout();
	end

	self:Style():ClearChanges();
end

function LayoutObject:GetPageLayout()
	if(self.page_layout) then
		return self.page_layout;
	end
	return self.parent:GetPageLayout()
end

--function LayoutObject:SelfNeedsLayout()
--	return self.needsLayout;
--end

--function LayoutObject:ChildrenNeedsLayout()
--	return self.childrenNeedsLayout;
--end

function LayoutObject:BeSubtreeRoot()
	return self.beSubtreeRoot
end

function LayoutObject:NeedsUpdateCSS()
	if(self.needsUpdateCss) then 
		return true;
	end
	return false;
end

function LayoutObject:UpdateCssStyle()
	self.needsUpdateCss = false;
	local control = self:GetControl();
	if(control) then
		control:ApplyCss(self:Style():GetStyle());
	end
end

function LayoutObject:UpdateLayoutIfNeeded(layout, beParentRelayout, beInDirtyRegion)
--	if(self:NeedsLayout() or beParentRelayout) then
--		self:UpdateLayout(layout, beParentRelayout);
--	else
----		local child = self:FirstChild();
----		while(child) do
----			self:UpdateChildLayout(nil, child);
----			child = child:NextSibling();
----		end
--		self:UpdateChildrenLayout();
--	end

	--self:UpdateChildrenLayout(layout);
end

function LayoutObject:CanHaveChildren()
	return true;
end

function LayoutObject:IsChildAllowed(child_layout_object, child_style)
	return true;
end

function LayoutObject:IsAbsolutePositioned()
	if(self:Style():Position() == "absolute") then
		return true;
	end
	return false;
end

function LayoutObject:IsRelativePositioned()
	if(self:Style():Position() == "relative") then
		return true;
	end
	return false;
end

-------------------------------------------------------------
-- virtual methods
-------------------------------------------------------------
function LayoutObject:UpdateLayout(layout,beParentRelayout, beInDirtyRegion)
	self:UpdateChildrenLayout(layout,beParentRelayout, beInDirtyRegion);

	if(self:NeedsUpdateCSS()) then
		self:UpdateCssStyle();
	end

	self.needsLayout = false;
	self.childrenNeedsLayout = false;
end


function LayoutObject:CreateLayout(child_index)
	
end

---------------------------------------------------------------------------------------------------
----------------	webkit/chromium	function
function LayoutObject:IsApplet()
	return false;
end
function LayoutObject:IsBR()
	return false;
end
function LayoutObject:IsBlockFlow()
	return false;
end
function LayoutObject:IsBoxModelObject()
	return false;
end
function LayoutObject:IsCounter()
	return false;
end
function LayoutObject:IsQuote()
	return false;
end
function LayoutObject:IsEmbeddedObject()
	return false;
end
function LayoutObject:IsFieldset()
	return false;
end
function LayoutObject:IsFileUploadControl()
	return false;
end
function LayoutObject:IsFrame()
	return false;
end
function LayoutObject:IsFrameSet()
	return false;
end
function LayoutObject:IsImage()
	return false;
end
function LayoutObject:IsInlineBlockOrInlineTable()
	return false;
end
function LayoutObject:IsListBox()
	return false;
end
function LayoutObject:IsListItem()
	return false;
end
function LayoutObject:IsListMarker()
	return false;
end
function LayoutObject:IsMedia()
	return false;
end
function LayoutObject:IsMenuList()
	return false;
end
function LayoutObject:IsMeter()
	return false;
end
function LayoutObject:IsProgress()
	return false;
end
function LayoutObject:IsLayoutBlock()
	return false;
end
function LayoutObject:IsLayoutButton()
	return false;
end
function LayoutObject:IsLayoutIFrame()
	return false;
end
function LayoutObject:IsLayoutImage()
	return false;
end
function LayoutObject:IsLayoutInline()
	return false;
end
function LayoutObject:IsLayoutPart()
	return false;
end
function LayoutObject:IsLayoutRegion()
	return false;
end
function LayoutObject:IsLayoutView()
	return false;
end
function LayoutObject:IsReplica()
	return false;
end
function LayoutObject:IsRuby()
	return false;
end
function LayoutObject:IsRubyBase()
	return false;
end
function LayoutObject:IsRubyRun()
	return false;
end
function LayoutObject:IsRubyText()
	return false;
end
function LayoutObject:IsSlider()
	return false;
end
function LayoutObject:IsSliderThumb()
	return false;
end
function LayoutObject:IsSummary()
	return false;
end
function LayoutObject:IsTable()
	return false;
end
function LayoutObject:IsTableCell()
	return false;
end
function LayoutObject:IsTableCol()
	return false;
end
function LayoutObject:IsTableRow()
	return false;
end
function LayoutObject:IsTableSection()
	return false;
end
function LayoutObject:IsTextControl()
	return false;
end
function LayoutObject:IsTextArea()
	return false;
end
function LayoutObject:IsTextField()
	return false;
end
function LayoutObject:IsVideo()
	return false;
end
function LayoutObject:IsWidget()
	return false;
end
function LayoutObject:IsCanvas()
	return false;
end
function LayoutObject:IsLayoutFullScreen()
	return false;
end
function LayoutObject:IsLayoutFullScreenPlaceholder()
	return false;
end
function LayoutObject:IsLayoutFlowThread()
	return false;
end

function LayoutObject:SetChildNeedsLayout(bChildrenNeedLayout, bMarkParents)
	local alreadyNeededLayout = self.normalChildNeedsLayout;
    self.normalChildNeedsLayout = bChildrenNeedLayout;
    if (bChildrenNeedLayout) then
        if (not alreadyNeededLayout and bMarkParents) then
            self:MarkContainingBlocksForLayout();
		end
    else
        self.posChildNeedsLayout = false;
        self.needsSimplifiedNormalFlowLayout = false;
        self.normalChildNeedsLayout = false;
        self.needsPositionedMovementLayout = false;
    end
end

function LayoutObject:IsAnonymous()
	return self.isAnonymous;
end

function LayoutObject:SetIsAnonymous(isAnonymous)
	self.isAnonymous = isAnonymous;
end

function LayoutObject:IsAnonymousBlock()
	return self.isAnonymous and (self:Style():Display() == "block" or self:Style():Display() == "box") and self:Style():StyleType() == "NOPSEUDO" and self:IsLayoutBlock() and self:IsListMarker();
end

function LayoutObject:IsAnonymousColumnsBlock()
	return self:Style():SpecifiesColumns() and self:IsAnonymousBlock();
end

function LayoutObject:IsAnonymousColumnSpanBlock()
	return self:Style():ColumnSpan() and self:IsAnonymousBlock();
end

function LayoutObject:IsRenderFlowThread()
	return false;
end

function LayoutObject:IsText()
	return self.isText;
end

function LayoutObject:IsBox()
	return self.isBox;
end

function LayoutObject:IsInline()
	return self.inline;
end

function LayoutObject:IsFloating()
	return self.floating;
end
-- absolute or fixed positioning
function LayoutObject:IsPositioned()
	return self.positioned;
end

-- absolute or fixed positioning
function LayoutObject:IsRelPositioned()
	return self.relPositioned;
end

function LayoutObject:IsReplaced()
	return self.replaced;
end

function LayoutObject:IsHorizontalWritingMode()
	return self.horizontalWritingMode;
end

function LayoutObject:IsRoot()
	--TODO: fixed this function
	return false;
end

function LayoutObject:IsBody()
	return self.node.name == "body";
end

function LayoutObject:IsHR()
	return self.node.name == "hr";
end

function LayoutObject:IsLegend()
	return self.node.name == "legend";
end

function LayoutObject:IsHTMLMarquee()
	return self.node.name == "marquee";
end

function LayoutObject:IsBeforeContent()
	if (self:Style():StyleType() ~= "BEFORE") then
		return false;
	end
	-- Text nodes don't have their own styles, so ignore the style on a text node.
	if (self:IsText() and not self:IsBR()) then
		return false;
	end
	return true;
end

function LayoutObject:IsAfterContent()
	if (self:Style():StyleType() ~= "AFTER") then
        return false;
	end
    -- Text nodes don't have their own styles, so ignore the style on a text node.
    if (self:IsText() and not self:IsBR()) then
        return false;
	end
    return true;
end

function LayoutObject:IsBeforeOrAfterContent()
	return self:IsBeforeContent() or self:IsAfterContent();
end
--@param obj: LayoutObject type
function LayoutObject.IsBeforeContent(obj)
	return obj and obj:IsBeforeContent();
end
--@param obj: LayoutObject type
function LayoutObject.IsAfterContent(obj)
	return obj and obj:IsAfterContent();
end
--@param obj: LayoutObject type
function LayoutObject.IsBeforeOrAfterContent(obj)
	return obj and obj:IsBeforeOrAfterContent();
end

function LayoutObject:FindBeforeContentRenderer()
--    local renderer = beforePseudoElementRenderer();
--    return isBeforeContent(renderer) ? renderer : 0;
end

function LayoutObject:FindAfterContentRenderer()
    local renderer = self:AfterPseudoElementRenderer();
	if(LayoutObject.IsAfterContent(renderer)) then
		return render;
	end
    return nil;
end

--function LayoutObject:AnonymousContainer(RenderObject* child)
--        RenderObject* container = child;
--        while (container->parent() != this)
--            container = container->parent();
--
--        ASSERT(container->isAnonymous());
--        return container;
--end

function LayoutObject:SetPositioned(value)
	if(value == nil) then
		value = true;
	end
	self.positioned = value;
end

function LayoutObject:SetRelPositioned(value)
	if(value == nil) then
		value = true;
	end
	self.relPositioned = value;
end

function LayoutObject:SetFloating(value)
	if(value == nil) then
		value = true;
	end
	self.floating = value;
end

function LayoutObject:SetInline(value)
	if(value == nil) then
		value = true;
	end
	self.inline = value;
end

function LayoutObject:SetIsText(value)
	if(value == nil) then
		value = true;
	end
	self.isText = value;
end

function LayoutObject:SetIsBox(value)
	if(value == nil) then
		value = true;
	end
	self.isBox = value;
end

function LayoutObject:SetIsReplace(value)
	if(value == nil) then
		value = true;
	end
	self.replaced = value;
end

function LayoutObject:SetHorizontalWritingMode(value)
	if(value == nil) then
		value = true;
	end
	self.horizontalWritingMode = value;
end

function LayoutObject:SetHasOverflowClip(value)
	if(value == nil) then
		value = true;
	end
	self.hasOverflowClip = value;
end

function LayoutObject:SetHasTransform(value)
	if(value == nil) then
		value = true;
	end
	self.hasTransform = value;
end

function LayoutObject:LayoutIfNeeded()
	if(self:NeedsLayout()) then 
		self:Layout();
	end
end

function LayoutObject:Layout()
	if(self:NeedsLayout()) then 
		local child = FirstChild();
		while (child) do
			child:LayoutIfNeeded();
			child = child:NextSibling();
		end
		SetNeedsLayout(false);
	end
end

function LayoutObject:Container()
	local object = self:Parent();

	if(self:IsText()) then
		return object;
	end

	local pos = self.style:Position();
	if(pos == "fixed") then
		while (object and object:Parent() and (not (object:HasTransform() and object:IsLayoutBlock()))) do
			object = object:Parent();
		end
	elseif(pos == "absolute") then
		while (object and object:Style():Position() == "static" and (not object:IsLayoutView()) and (not (object:HasTransform() and object:IsLayoutBlock()))) do
			object = object:Parent();
		end
	end
	return object;
end

-- TODO: 回溯父对象，添加相应布局标志
-- @param scheduleRelayout:
-- @param newRoot:
function LayoutObject:MarkContainingBlocksForLayout(scheduleRelayout, newRoot)
	local object = self:Container();
	local last = self;

	local simplifiedNormalFlowLayout = self:NeedsSimplifiedNormalFlowLayout() and (not self:SelfNeedsLayout()) and (not self:NormalChildNeedsLayout());

	while(object) do
		local container = object:Container();
		-- Don't mark the outermost object of an unrooted subtree. That object will be marked when the subtree is added to the document.
		if (not container and (not object:IsLayoutView())) then
            return;
		end
		if(not last:IsText() and (last:Style():Position() == "absolute" or last:Style():Position() == "fixed") ) then
			local willSkipRelativelyPositionedInlines = not object:IsLayoutBlock();
			while (object and not object:IsLayoutBlock()) do -- Skip relatively positioned inlines and get to the enclosing RenderBlock.
                object = object:Container();
			end
			if(object and not object:IsLayoutBlock()) then
				return;
			end
			if(willSkipRelativelyPositionedInlines) then
				container = object:Container();
			end
			object.posChildNeedsLayout = true;
			simplifiedNormalFlowLayout = true;
		elseif(simplifiedNormalFlowLayout) then
			if(object.needsSimplifiedNormalFlowLayout) then
				return;
			end
			object.needsSimplifiedNormalFlowLayout = true;
		else
			if(object.normalChildNeedsLayout) then
				return;
			end
			object.normalChildNeedsLayout = true;
		end

		if(object == newRoot) then
			return;
		end

		last = object;
		object = container;
	end
end

function LayoutObject:SelfNeedsLayout()
	return self.needsLayout;
end

function LayoutObject:NeedsSimplifiedNormalFlowLayout()
	return self.needsSimplifiedNormalFlowLayout;
end

function LayoutObject:NormalChildNeedsLayout()
	return self.normalChildNeedsLayout;
end

function LayoutObject:PosChildNeedsLayout()
	return self.posChildNeedsLayout;
end

function LayoutObject:NeedsPositionedMovementLayout()
	return self.needsPositionedMovementLayout;
end

function LayoutObject:IsSetNeedsLayoutForbidden()
	return self.setNeedsLayoutForbidden;
end

function LayoutObject:PreferredLogicalWidthsDirty()
	return self.preferredLogicalWidthsDirty;
end

function LayoutObject:HasTransform()
	return self.hasTransform;
end

function LayoutObject:HasColumns()
	return self.hasColumns;
end

function LayoutObject:InRenderFlowThread()
	return self.inRenderFlowThread;
end

function LayoutObject:SetInRenderFlowThread(b)
	if(b == nil) then
		b = true;
	end
	self.inRenderFlowThread = b;
end

function LayoutObject:HasClip()
	--return self:IsPositioned() and style()->hasClip();
	-- FIXME: complete the style function "hasClip";
	return self:IsPositioned();
end

function LayoutObject:HasOverflowClip()
	return self.hasOverflowClip;
end

function LayoutObject:HasMask()
	--return style() && style()->hasMask();
	return false;
end

function LayoutObject:ChildrenInline()
	return self.childrenInline;
end

function LayoutObject:SetChildrenInline(value)
	self.childrenInline = value;
end

function LayoutObject:SetNeedsLayout(needsLayout, markParents)
	local alreadyNeededLayout = self.needsLayout;
	self.needsLayout = needsLayout;
	if(needsLayout) then
		if(not alreadyNeededLayout) then
			if(markParents) then
				self:MarkContainingBlocksForLayout();
			end
		end
	else
		self.everHadLayout = true;
		self.posChildNeedsLayout = false;
		self.normalChildNeedsLayout = false;
		self.needsPositionedMovementLayout = false;
		self.needsSimplifiedNormalFlowLayout = false;
	end
end

function LayoutObject:SetPreferredLogicalWidthsDirty(dirty, markParents)
	local alreadyDirty = self.preferredLogicalWidthsDirty;
    self.preferredLogicalWidthsDirty = dirty;
    if (dirty and not alreadyDirty and markParents and (self:IsText() or (self:Style():Position() ~= "fixed" and self:Style():Position() ~= "absolute"))) then
        self:InvalidateContainerPreferredLogicalWidths();
	end
end

function LayoutObject:InvalidateContainerPreferredLogicalWidths()
	local object = if_else(self:IsTableCell(),self:ContainingBlock(),self:Container());
	while (object and not object.preferredLogicalWidthsDirty) do
        -- Don't invalidate the outermost object of an unrooted subtree. That object will be 
        -- invalidated when the subtree is added to the document.
        local container = if_else(object:IsTableCell(),object:ContainingBlock(),object:Container());
        if (not container and not object:IsLayoutView()) then
            break;
		end
        object.preferredLogicalWidthsDirty = true;
        if (object:Style():Position() == "fixed" or object:Style():Position() == "absolute") then
            -- A positioned object has no effect on the min/max width of its containing block ever.
            -- We can optimize this case and not go up any further.
            break;
		end
        object = container;
    end
end

function LayoutObject:NeedsLayout()
	return self.needsLayout or self.normalChildNeedsLayout or self.posChildNeedsLayout or self.needsPositionedMovementLayout or self.needsSimplifiedNormalFlowLayout;
end

function LayoutObject:Style()
	return self.style;
end

function LayoutObject:Node()
	return self.node;
end

function LayoutObject:Parent()
	return self.parent;
end


function LayoutObject:ContainingBlock()
	local o = self:Parent();
	if (not self:IsText() and self.style:Position() == "fixed") then
        while (o and o:IsLayoutView() and not(o:HasTransform() and o:IsLayoutBlock())) do
            o = o:Parent();
		end
	elseif(not self:IsText() and self.style:Position() == "absolute") then
		while (o and (o:Style():Position() == "static" or (o:IsInline() and not o:IsReplaced())) and not o:IsLayoutView() and not (o:HasTransform() and o:IsLayoutBlock())) do
			if (o:Style():Position() == "relative" and o:IsInline() and not o:IsReplaced()) then
                return o:ContainingBlock();
			end
			o = o:Parent();
		end
	else
		while (o and ((o:IsInline() and not o:IsReplaced()) or o:IsTableRow() or o:IsTableSection() or o:IsTableCol() or o:IsFrameSet() or o:IsMedia())) do
			 o = o:Parent();
		end
	end

	if (not o or not o:IsLayoutBlock()) then
        return; -- This can still happen in case of an orphaned tree
	end

	return o;
end

function LayoutObject:WillBeDestroyed()
	--TODO: fixed this function
end

function LayoutObject:Destroy()
    self:WillBeDestroyed();
	--TODO: fixed this function
    --self:ArenaDelete(renderArena(), this);
end

-- virtual function
function LayoutObject:DirtyLinesFromChangedChild(child)
	
end

function LayoutObject:VirtualChildren()
	return;
end

function LayoutObject:AfterPseudoElementRenderer()
	local children = self:VirtualChildren();
	if (children) then
        return children:AfterPseudoElementRenderer(self);
	end
    return nil;
end

function LayoutObject:SetNeedsLayoutAndPrefWidthsRecalc()
	self:SetNeedsLayout(true);
    self:SetPreferredLogicalWidthsDirty(true);
end

function LayoutObject:IsFloatingOrPositioned()
	return self:IsFloating() or self:IsPositioned();
end

function LayoutObject:IsDeprecatedFlexibleBox()
	return false;
end

function LayoutObject:IsFlexingChildren()
	return false;
end

function LayoutObject:IsMarginBeforeQuirk()
	return self.marginBeforeQuirk;
end

function LayoutObject:IsMarginAfterQuirk()
	return self.marginAfterQuirk;
end

function LayoutObject:SetMarginBeforeQuirk(b)
	b = if_else(b == nil, true, b);
	self.marginBeforeQuirk = b;
end

function LayoutObject:SetMarginAfterQuirk(b)
	b = if_else(b == nil, true, b);
	self.marginAfterQuirk = b;
end